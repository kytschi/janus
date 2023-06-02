# JANUS
`The spirit of the doorways`

A tool for blacklisting IPs based on specific patterns/strings found in webserver logs.

## BE WARNED! Janus is very aggressive!
Make sure to carefully build your whitelist so not to block valid services or servers.

![Snapshot](https://github.com/kytschi/janus/blob/main/screenshot.jpg)

## Setup

### Step 1: clone the repository
Clone or download the repository to your webserver.

### Step 2: setup the database
In the Janus folder copy `janus.db.example` to `janus.db`. You can place this SQLite databse anywhere you like, it doesn't have to be in the Janus folder.

Make sure the `janus.db` file has write permissions by the webserver user.

### Step 3: generate a janus key
Run a command like this,
```sh
openssl rand -out janus.key -hex 32
```

The key is used in the url to help keep unwanted traffic from finding the Janus login.

### Step 4: setup the index.php
Inside the `public` folder there is an example file called `index.example.php` you can use this as your `index.php`. Copy that to you root folder for where you want Janus hosted from or point your webserver to the `public` folder.

**DO NOT BE STUPID AND HAVE THE DB AND THE KEY IN THE SAME FOLDER AS THE `index.php`!**

Open the `index.php` and replace the lines with location of where your files are.

```php
$db = '/var/www/janus/janus.db';
$key = '/var/www/janus/janus.key';
```

### Step 5: login and configure the settings
The default login is username: `janus` and password: `letmein` **CHANGE THIS!** Go to `settings` and this from their `users` then update the username and password to whatever you like. Don't use something like `admin` or `root` be creative.

Next from the `settings` set the various folders and commands to match your server setup.

The `CRON output folder` is where a cron file is generated to allow you to run a cron to trigger Janus to automatically scan. Make sure your webserver user has write permissions to the `CRON output folder` folder.

### Step 6: the cron
Once you've saved your settings, Janus should have written a `cron.sh` file in the `CRON output folder`, double check that its there. If its not make sure the webserver user has permissions to write to that folder and click `save` again from the `settings`.

Now set yourself a `cron` up to trigger the `cron.sh` at a time that suits you. Something like,
```sh
0 0 * * * sh /var/www/janus/cron/cron.sh
```

## Credits
Janus background - Deep Ellum Janus, by Dan Colcer (Transylvania, Romania @dcolcerart) was painted in 2016.

Icons from https://icons8.com

Name the show this is named from? ;-)