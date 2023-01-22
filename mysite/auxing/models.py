from django.db import models

class song(models.Model):
    uri = models.CharField(max_length=100)
    title = models.CharField(max_length=100)
    artist = models.CharField(max_length=100)
    duration = models.DecimalField(decimal_places=1, max_digits=4)
    albumcover = models.ImageField()
    votes = models.IntegerField()

class Meta:
    db_table = "song"

# Create your models here.
