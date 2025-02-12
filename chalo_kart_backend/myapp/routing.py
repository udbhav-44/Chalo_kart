from django.urls import re_path
from . import consumers

websocket_urlpatterns = [
    re_path(r'ws/trips/(?P<trip_id>\w+)/$', consumers.TripConsumer.as_asgi()),
]
