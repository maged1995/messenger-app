from messenger_app.models import *
from rest_framework import serializers


class ChatUserSerializer(serializers.HyperlinkedModelSerializer):
    messages = serializers.HyperlinkedRelatedField(
        many=True, view_name='message-detail', read_only=True)

    class Meta:
        model = ChatUser
        fields = ['url', 'username', 'email', 'user_image', 'messages']


class ChatSerializer(serializers.HyperlinkedModelSerializer):
    class Meta:
        model = Chat
        fields = ['id', 'created', 'isGroup']


class ChatUserChatSerializer(serializers.HyperlinkedModelSerializer):
    chatuser = serializers.HyperlinkedIdentityField(
        view_name='chatuser-detail', format='html')

    class Meta:
        model = ChatUserChat
        fields = ['id', 'chatuser', 'chat']


class MessageSerializer(serializers.HyperlinkedModelSerializer):
    chatuser = serializers.HyperlinkedIdentityField(
        view_name='chatuser-detail', format='html')

    class Meta:
        model = Message
        fields = ['id', 'chatuser', 'message', 'chat']


# class SnippetSerializer(serializers.HyperlinkedModelSerializer):
#     owner = serializers.ReadOnlyField(source='owner.username')
#     highlight = serializers.HyperlinkedIdentityField(view_name='snippet-highlight', format='html')

#     class Meta:
#         model = Snippet
#         fields = ['url', 'id', 'highlight', 'owner',
#                   'title', 'code', 'linenos', 'language', 'style']


# class UserSerializer(serializers.HyperlinkedModelSerializer):
#     snippets = serializers.HyperlinkedRelatedField(many=True, view_name='snippet-detail', read_only=True)

#     class Meta:
#         model = User
#         fields = ['url', 'id', 'username', 'snippets']
