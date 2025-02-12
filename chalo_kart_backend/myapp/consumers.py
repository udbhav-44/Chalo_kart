import json
from channels.generic.websocket import AsyncWebsocketConsumer
from channels.db import database_sync_to_async
from django.core.exceptions import ObjectDoesNotExist
from .models import Trip
import logging

logger = logging.getLogger(__name__)

class TripConsumer(AsyncWebsocketConsumer):
    async def connect(self):
        try:
            self.trip_id = self.scope['url_route']['kwargs']['trip_id']
            self.room_group_name = f'trip_{self.trip_id}'

            # Verify trip exists and user has access
            if not await self.can_access_trip():
                await self.close()
                return

            # Join room group
            await self.channel_layer.group_add(
                self.room_group_name,
                self.channel_name
            )

            await self.accept()
            
            # Send initial trip state
            trip_data = await self.get_trip_data()
            if trip_data:
                await self.send(text_data=json.dumps(trip_data))
                
        except Exception as e:
            logger.error(f"Error in WebSocket connect: {str(e)}")
            await self.close()

    async def disconnect(self, close_code):
        try:
            # Leave room group
            await self.channel_layer.group_discard(
                self.room_group_name,
                self.channel_name
            )
        except Exception as e:
            logger.error(f"Error in WebSocket disconnect: {str(e)}")

    async def receive(self, text_data):
        try:
            text_data_json = json.loads(text_data)
            message_type = text_data_json.get('type')
            
            if message_type == 'location_update':
                location = text_data_json.get('location')
                if location and await self.can_update_location():
                    updated = await self.update_location(location)
                    if updated:
                        # Send location update to room group
                        await self.channel_layer.group_send(
                            self.room_group_name,
                            {
                                'type': 'location_update',
                                'location': location
                            }
                        )
            
        except json.JSONDecodeError:
            logger.error("Invalid JSON received")
        except Exception as e:
            logger.error(f"Error processing WebSocket message: {str(e)}")

    async def location_update(self, event):
        try:
            location = event['location']
            await self.send(text_data=json.dumps({
                'type': 'location_update',
                'location': location
            }))
        except Exception as e:
            logger.error(f"Error sending location update: {str(e)}")

    async def trip_update(self, event):
        try:
            await self.send(text_data=json.dumps(event))
        except Exception as e:
            logger.error(f"Error sending trip update: {str(e)}")

    @database_sync_to_async
    def can_access_trip(self):
        try:
            trip = Trip.objects.get(trip_id=self.trip_id)
            # Add your access control logic here
            # For example, check if the user is the driver or passenger
            return True
        except ObjectDoesNotExist:
            return False

    @database_sync_to_async
    def can_update_location(self):
        try:
            trip = Trip.objects.get(trip_id=self.trip_id)
            # Add your authorization logic here
            # For example, check if the user is the driver
            return True
        except ObjectDoesNotExist:
            return False

    @database_sync_to_async
    def update_location(self, location):
        try:
            trip = Trip.objects.get(trip_id=self.trip_id)
            if trip.status != 'Completed':
                if 'latitude' in location and 'longitude' in location:
                    trip.driver.location = {
                        'latitude': location['latitude'],
                        'longitude': location['longitude']
                    }
                    trip.driver.save()
                    return True
            return False
        except ObjectDoesNotExist:
            return False

    @database_sync_to_async
    def get_trip_data(self):
        try:
            trip = Trip.objects.get(trip_id=self.trip_id)
            return {
                'type': 'trip_state',
                'status': trip.status,
                'driver_location': trip.driver.location if trip.driver else None,
                'start_location': trip.start_location,
                'end_location': trip.end_location,
            }
        except ObjectDoesNotExist:
            return None
