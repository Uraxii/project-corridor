import asyncio
import subprocess
import signal
import os
import uuid
from typing import Dict, Optional, List
from datetime import datetime, timedelta
import docker
from docker.errors import DockerException

from app.models.shard_models import (
    ShardInfo, ShardType, ShardStatus, ShardCreateRequest, 
    ShardConnectionInfo
)
from app.core.config import settings


class ShardProcess:
    """Represents a running shard process."""
    
    def __init__(self, shard_info: ShardInfo):
        self.shard_info = shard_info
        self.process: Optional[subprocess.Popen] = None
        self.container = None  # Docker container if using Docker
        self.last_heartbeat = datetime.utcnow()


class ShardManagerCore:
    """Core shard management functionality."""
    
    def __init__(self):
        self.shards: Dict[str, ShardProcess] = {}
        self.used_ports: set = set()
        self.docker_client = None
        self._heartbeat_task: Optional[asyncio.Task] = None
        
    
    async def initialize(self):
        """Initialize the shard manager."""
        if settings.USE_DOCKER:
            try:
                self.docker_client = docker.from_env()
                print("Docker client initialized")
            except DockerException as e:
                print(f"Failed to initialize Docker client: {e}")
                raise
        
        # Start heartbeat monitoring
        self._heartbeat_task = asyncio.create_task(
            self._heartbeat_monitor()
        )
        print("Shard manager initialized")
    
    
    async def shutdown(self):
        """Shutdown all shards and cleanup."""
        if self._heartbeat_task:
            self._heartbeat_task.cancel()
        
        # Stop all shards
        for shard_id in list(self.shards.keys()):
            await self.stop_shard(shard_id)
        
        if self.docker_client:
            self.docker_client.close()
        
        print("Shard manager shutdown complete")
    
    
    def _get_next_available_port(self) -> Optional[int]:
        """Get the next available port for a shard."""
        for port in range(
            settings.SHARD_PORT_RANGE_START, 
            settings.SHARD_PORT_RANGE_END + 1
        ):
            if port not in self.used_ports:
                return port
        return None
    
    
    async def create_shard(self, request: ShardCreateRequest) -> Optional[ShardInfo]:
        """Create a new shard."""
        if len(self.shards) >= settings.MAX_SHARDS:
            print(f"Maximum shard limit reached: {settings.MAX_SHARDS}")
            return None
        
        port = self._get_next_available_port()
        if not port:
            print("No available ports for new shard")
            return None
        
        shard_id = str(uuid.uuid4())
        name = request.name or f"{request.shard_type}_{shard_id[:8]}"
        
        shard_info = ShardInfo(
            shard_id=shard_id,
            shard_type=request.shard_type,
            name=name,
            status=ShardStatus.STARTING,
            host="localhost",  # Will be container IP if using Docker
            port=port,
            max_players=request.max_players,
            created_at=datetime.utcnow(),
            dungeon_id=request.dungeon_id,
            game_settings=request.game_settings
        )
        
        shard_process = ShardProcess(shard_info)
        
        # Start the shard process
        success = await self._start_shard_process(shard_process)
        if not success:
            return None
        
        self.shards[shard_id] = shard_process
        self.used_ports.add(port)
        
        print(f"Created shard: {shard_id} on port {port}")
        return shard_info
    
    
    async def create_hub_shard(self) -> Optional[ShardInfo]:
        """Create the persistent player hub shard."""
        request = ShardCreateRequest(
            shard_type=ShardType.HUB,
            name=settings.HUB_SHARD_NAME,
            max_players=settings.HUB_MAX_PLAYERS
        )
        return await self.create_shard(request)
    
    
    async def _start_shard_process(self, shard: ShardProcess) -> bool:
        """Start a shard process (Docker or direct)."""
        if settings.USE_DOCKER:
            return await self._start_docker_shard(shard)
        else:
            return await self._start_direct_shard(shard)
    
    
    async def _start_docker_shard(self, shard: ShardProcess) -> bool:
        """Start shard in Docker container."""
        try:
            container = self.docker_client.containers.run(
                settings.DOCKER_IMAGE,
                command=[
                    "--headless",
                    "--server",
                    f"--port={shard.shard_info.port}",
                    f"--shard-id={shard.shard_info.shard_id}",
                    f"--shard-type={shard.shard_info.shard_type}",
                    f"--max-players={shard.shard_info.max_players}"
                ],
                ports={f'{shard.shard_info.port}/tcp': shard.shard_info.port},
                network=settings.DOCKER_NETWORK,
                detach=True,
                name=f"shard_{shard.shard_info.shard_id}",
                environment={
                    'SHARD_ID': shard.shard_info.shard_id,
                    'SHARD_TYPE': shard.shard_info.shard_type,
                    'MAX_PLAYERS': str(shard.shard_info.max_players),
                    'MANAGER_HOST': settings.HOST,
                    'MANAGER_PORT': str(settings.PORT)
                }
            )
            
            shard.container = container
            shard.shard_info.status = ShardStatus.RUNNING
            shard.shard_info.host = container.attrs['NetworkSettings']['Networks'][settings.DOCKER_NETWORK]['IPAddress']
            
            print(f"Started Docker shard: {shard.shard_info.shard_id}")
            return True
            
        except DockerException as e:
            print(f"Failed to start Docker shard: {e}")
            shard.shard_info.status = ShardStatus.ERROR
            return False
    
    
    async def _start_direct_shard(self, shard: ShardProcess) -> bool:
        """Start shard as direct process."""
        try:
            # Updated command line arguments to match Godot client expectations
            cmd = [
                settings.GODOT_SERVER_EXECUTABLE,
                "--headless",
                "--server",
                f"--port={shard.shard_info.port}",
                f"--shard-id={shard.shard_info.shard_id}",
                f"--shard-type={shard.shard_info.shard_type}",
                f"--max-players={shard.shard_info.max_players}",
                f"--manager-host={settings.HOST}",
                f"--manager-port={settings.PORT}"
            ]
            
            env = os.environ.copy()
            env.update({
                'SHARD_ID': shard.shard_info.shard_id,
                'SHARD_TYPE': shard.shard_info.shard_type,
                'MAX_PLAYERS': str(shard.shard_info.max_players),
                'MANAGER_HOST': settings.HOST,
                'MANAGER_PORT': str(settings.PORT),
                'DISPLAY': ':99'  # For headless operation
            })
            
            print(f"Starting shard with command: {' '.join(cmd)}")
            
            shard.process = subprocess.Popen(
                cmd,
                cwd=settings.GODOT_PROJECT_PATH,
                env=env,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                start_new_session=True  # Create new process group for clean shutdown
            )
            
            # Wait a moment to see if process starts successfully
            await asyncio.sleep(2)
            
            if shard.process.poll() is None:
                shard.shard_info.status = ShardStatus.RUNNING
                print(f"Started direct shard: {shard.shard_info.shard_id} (PID: {shard.process.pid})")
                return True
            else:
                stdout, stderr = shard.process.communicate()
                print(f"Shard process failed to start:")
                print(f"STDOUT: {stdout.decode()}")
                print(f"STDERR: {stderr.decode()}")
                shard.shard_info.status = ShardStatus.ERROR
                return False
            
        except Exception as e:
            print(f"Failed to start direct shard: {e}")
            shard.shard_info.status = ShardStatus.ERROR
            return False
    
    
    async def stop_shard(self, shard_id: str) -> bool:
        """Stop a shard."""
        if shard_id not in self.shards:
            return False
        
        shard = self.shards[shard_id]
        shard.shard_info.status = ShardStatus.STOPPING
        
        try:
            if shard.container:
                shard.container.stop(timeout=10)
                shard.container.remove()
            elif shard.process:
                shard.process.terminate()
                try:
                    shard.process.wait(timeout=10)
                except subprocess.TimeoutExpired:
                    shard.process.kill()
            
            self.used_ports.discard(shard.shard_info.port)
            del self.shards[shard_id]
            
            print(f"Stopped shard: {shard_id}")
            return True
            
        except Exception as e:
            print(f"Error stopping shard {shard_id}: {e}")
            return False
    
    
    def get_shard(self, shard_id: str) -> Optional[ShardInfo]:
        """Get shard information."""
        if shard_id in self.shards:
            return self.shards[shard_id].shard_info
        return None
    
    
    def list_shards(self) -> List[ShardInfo]:
        """List all shards."""
        return [shard.shard_info for shard in self.shards.values()]
    
    
    def get_hub_shard(self) -> Optional[ShardConnectionInfo]:
        """Get the hub shard connection info."""
        for shard in self.shards.values():
            if shard.shard_info.shard_type == ShardType.HUB:
                return ShardConnectionInfo(
                    shard_id=shard.shard_info.shard_id,
                    host=shard.shard_info.host,
                    port=shard.shard_info.port,
                    shard_type=shard.shard_info.shard_type,
                    name=shard.shard_info.name,
                    current_players=shard.shard_info.current_players,
                    max_players=shard.shard_info.max_players
                )
        return None
    
    
    def update_shard_stats(self, shard_id: str, 
                          current_players: int) -> bool:
        """Update shard statistics."""
        if shard_id in self.shards:
            self.shards[shard_id].shard_info.current_players = current_players
            self.shards[shard_id].last_heartbeat = datetime.utcnow()
            return True
        return False
    
    
    async def _heartbeat_monitor(self):
        """Monitor shard heartbeats and cleanup dead shards."""
        while True:
            try:
                current_time = datetime.utcnow()
                dead_shards = []
                
                for shard_id, shard in self.shards.items():
                    # Check if shard hasn't sent heartbeat in 60 seconds
                    if (current_time - shard.last_heartbeat).seconds > 60:
                        print(f"Shard {shard_id} appears dead, cleaning up...")
                        dead_shards.append(shard_id)
                
                # Cleanup dead shards
                for shard_id in dead_shards:
                    await self.stop_shard(shard_id)
                
                await asyncio.sleep(30)  # Check every 30 seconds
                
            except asyncio.CancelledError:
                break
            except Exception as e:
                print(f"Error in heartbeat monitor: {e}")
                await asyncio.sleep(30)


# Global shard manager instance
shard_manager = ShardManagerCore()
