from django.urls import path
from . import views

app_name = 'auxing'
urlpatterns = [
    path('', views.index, name='index'),
    path('poopoo/', views.poopoo, name='poopoo'),
    path('search/', views.search, name='search'),
    path('authenticate/', views.authenticate, name='authenticate'),
    path('addToList/', views.addToList, name='addToList'),
    path('getList/', views.getList, name="getList"),
    path('vote/', views.vote, name='vote'),
]