# Generated by Django 4.1.1 on 2023-01-21 19:48

from django.db import migrations, models


class Migration(migrations.Migration):

    initial = True

    dependencies = [
    ]

    operations = [
        migrations.CreateModel(
            name='song',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('uri', models.CharField(max_length=100)),
                ('title', models.CharField(max_length=100)),
                ('artist', models.CharField(max_length=100)),
                ('duration', models.DecimalField(decimal_places=1, max_digits=4)),
                ('albumcover', models.ImageField(upload_to='')),
                ('votes', models.IntegerField()),
            ],
        ),
    ]
