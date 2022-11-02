from django.shortcuts import render
from messenger_app.models import ChatUser
from rest_framework import generics
from messenger_app.serializers import *


class UserList(generics.ListCreateAPIView):
    queryset = ChatUser.objects.all()
    serializer_class = ChatUserSerializer


class UserView(generics.RetrieveUpdateDestroyAPIView):
    queryset = ChatUser.objects.all()
    serializer_class = ChatUserSerializer


class ChatList(generics.ListCreateAPIView):
    queryset = Chat.objects.all()
    serializer_class = ChatSerializer


class ChatView(generics.RetrieveUpdateDestroyAPIView):
    queryset = Chat.objects.all()
    serializer_class = ChatSerializer


class MessageList(generics.ListCreateAPIView):
    queryset = Message.objects.all()
    serializer_class = MessageSerializer


class MessageView(generics.RetrieveUpdateDestroyAPIView):
    queryset = Message.objects.all()
    serializer_class = MessageSerializer
