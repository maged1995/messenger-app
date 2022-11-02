from django.db import models
from django.contrib import auth
from django.core.exceptions import ValidationError
# Create your models here.


class ChatUser(auth.models.User):
    user_image = models.ImageField(
        upload_to="static",
        height_field=None,
        width_field=None,
        max_length=100)


class Chat(models.Model):
    created = models.DateTimeField(auto_now_add=True)
    is_group = models.BooleanField()

    def clean(self):
        if self.group or self.chat_user_chat_set.count() != 2:
            raise ValidationError('individual chat should have two users.')


class ChatUserChat(models.Model):
    chatuser = models.ForeignKey(ChatUser, on_delete=models.CASCADE)
    chat = models.ForeignKey(Chat, on_delete=models.CASCADE)


class Message(models.Model):
    created = models.DateTimeField(auto_now_add=True)
    message = models.TextField()
    chatuser = models.ForeignKey(
        ChatUser,
        related_name='messages',
        on_delete=models.CASCADE)
    chat = models.ForeignKey(
        Chat,
        related_name='messages',
        on_delete=models.CASCADE)
