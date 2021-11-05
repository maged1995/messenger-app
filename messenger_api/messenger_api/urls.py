"""messenger_api URL Configuration

The `urlpatterns` list routes URLs to views. For more information please see:
    https://docs.djangoproject.com/en/3.2/topics/http/urls/
Examples:
Function views
    1. Add an import:  from my_app import views
    2. Add a URL to urlpatterns:  path('', views.home, name='home')
Class-based views
    1. Add an import:  from other_app.views import Home
    2. Add a URL to urlpatterns:  path('', Home.as_view(), name='home')
Including another URLconf
    1. Import the include() function: from django.urls import include, path
    2. Add a URL to urlpatterns:  path('blog/', include('blog.urls'))
"""
from django.urls import include, path
from rest_framework import routers
from messenger_app import views

# router = routers.DefaultRouter()
# router.register(r'users', views.UserList)
# router.register(r'groups', views.GroupView)


urlpatterns = [
    path('api-auth/', include('rest_framework.urls')),
    path('users/', views.UserList.as_view(), name="chatuser-list"),
    path('users/<int:pk>/', views.UserView.as_view(), name="chatuser-detail"),
    path('chat/', views.ChatList.as_view(), name="chat-list"),
    path('chat/<int:pk>/', views.ChatView.as_view(), name="chat-detail"),
    path('message/', views.MessageList.as_view(), name="message-list"),
    path('message/<int:pk>/', views.MessageView.as_view(), name="message-detail"),
]
