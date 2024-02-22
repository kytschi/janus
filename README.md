# JANUS
`The spirit of the doorways`

A tool for blacklisting IPs based on specific patterns/strings found in webserver logs.

## BE WARNED! Janus is very aggressive!
Make sure to carefully build your whitelist so not to block valid services or servers.

![Snapshot](https://github.com/kytschi/janus/blob/main/screenshot.jpg)

## Requirements
* PHP 7.4 or 8+
* PHP-PDO
* PHP-GD
* PHP-SQLite (optional depending on your preferred db choice)
* PHP-Mysql (optional depending on your preferred db choice)
* iptables, IPv6 has been added but the pattern parsing is a pain and it might result in invalid matches.
* any log with URLs and IPs.
* geoiplookup (OPTIONAL, only if you want to lookup the country of origin)
* whois (OPTIONAL, only if you want to lookup the service)

## Setup

### Step 1: clone the repository
Clone or download the repository to your webserver.

### Step 2: setup up the Janus PHP module
Copy one of the pre-compiled PHP modules from the `compiled` folder for your PHP version to your PHP modules folder and create a PHP ini for the module.

OR

Create a PHP module ini and point it to one of the modules in the `compiled` folder that matches your PHP version.

For example in `/etc/php/8.1/modules/janus.ini` we tell it to look for the module as such,
```sh
; configuration for php to enable janus
extension=/var/www/janus/compiled/php8.1-janus.so
```

Don't forget to then configure your PHP cli and FPM (if using it) to load the Janus module. Normally you'd just symlink the `janus.ini` in the `modules` folder is your under Linux.

If you have problems with the pre-compiled try building it yourself either via running the `build.sh` (it'll need composer) or installing Zephir (https://zephir-lang.com/en) and building with that. The `build.sh` tries to build for all the PHPs so you may want to mod the script to build only for what you need.

### Step 3: setup the database
In the Janus folder copy `janus.db.example` to `janus.db`. You can place this SQLite databse anywhere you like, it doesn't have to be in the Janus folder.

Make sure the `janus.db` file has write permissions by the webserver user.

If you'd prefer to have MySQL/MariaDB support then create a database called `janus` for example and run the 
`mysql.sql` sql file located in the Janus folder against the database.

Remember to create a username for the database with a nice password and give it read/write access.

### Step 4: generate a janus key
Run a command like this,
```sh
openssl rand -out janus.key -hex 32
```

The key is used in the url to help keep unwanted traffic from finding the Janus login.

### Step 5: setup the index.php
Inside the `public` folder there is an example file called `index.example.php` you can use this as your `index.php`. Copy that to you root folder for where you want Janus hosted from or point your webserver to the `public` folder.

**DO NOT BE STUPID AND HAVE THE DB AND THE KEY IN THE SAME FOLDER AS THE `index.php`!**

Open the `index.php` and replace the lines with location of where your files are.

```php
$db = 'sqlite:/var/www/janus/janus.db';
$key = '/var/www/janus/janus.key';
```

If you'd like to use MySQL/MariaDB over SQLite then use the following.
```php
$db = 'mysql:dbname=janus;host=127.0.0.1;UID=janus;PWD=janus;';
```

### Step 6: login and configure the settings
The default login is username: `janus` and password: `letmein` **CHANGE THIS!** Go to `settings` and from there `users` then update the username and password to whatever you like. **Don't use something like `admin` or `root` be creative!**

Next from the `settings` set the various folders and commands to match your server setup.

The `CRON output folder` is where a cron file is generated to allow you to run a cron to trigger Janus to automatically scan. Make sure your webserver user has write permissions to the `CRON output folder` folder.

**Make sure that the webserver user can read those webserver log files also.**

### Step 7: the cron
Once you've saved your settings, Janus should have written a `cron.sh` file in the `CRON output folder`, double check that its there. If its not make sure the webserver user has permissions to write to that folder and click `save` again from the `settings`.

Now set yourself a `cron` up to trigger the `cron.sh` at a time that suits you. Something like,
```sh
0 4 * * * sh /var/www/janus/cron/cron.sh > /dev/null 2>&1
```

Depending on how often you run the cron, I'd recommend that you watch the previous days logs and make sure you log rotate accordingly. This way you'll be blocking suspicious activing from the day before rather than on the day. Of course if your watching the logs faster than every 24hrs then use the current day's logs. This I just find this a good way of teaching the system what to watch for a block pattern without removing those suspicious requests too fast.

Once you've got the patterns down, move to live logs and up your cron watch time.

## Updating

Either git pull, clone or download the latest from the repo to keep Janus up to date.

**DO NOT FORGET TO RESTART THE PHP SERVER**

### Migrations
To update the database with the latest migrations, make sure the webserver user can write to the `migrations` folder in the `cron` folder and go to `settings` in Janus and click save.

This will create a bash script called `migrations.sh` simply run this from your terminal and any new migrations will be executed. The `migrations.sh` is located in the `cron/migrations` folder.

## Logs
I've managed to test this with nginx, apache, ssh and mail logs. So far it's managed to find the pattern and IPs from them. If your find it's not working for your logs either open an issue with a sample of your log (DONT SHARE SENSITIVE INFO) or drop me a message at dev@kytschi.com and I'll see if I can sort it.

## Notes on iptables
If you have other entries in your iptables that could override what Janus is doing it would be worth you moving the `JANUS_BLACKLIST` and `JANUS_WHITELIST` entries above those that conflict.

A little howto but feel free to look up a better method.

Display iptables lines number:

```
iptables -L -n INPUT --line-numbers

Chain INPUT (policy ACCEPT)
num  target             prot opt source               destination         
1    ACCEPT             all  --  192.168.1.2          0.0.0.0/0            
2    ACCEPT             all  --  192.168.1.3          0.0.0.0/0        
3    ACCEPT             all  --  192.168.1.4          0.0.0.0/0
4    JANUS_BLACKLIST    all  --  0.0.0.0/0            0.0.0.0/0
```

Let's say that you want to move the rule num 4 to the rule num 1 do this:

```
iptables -I INPUT 1 -j JANUS_BLACKLIST
```
-I: to insert

INPUT: Name of the chain

1: Position number where you want to insert the chain

-j: rule to insert at the position number

As we insert a new rule, the old rule that was in the fourth position is now in the fifth position.

Delete your old rule num 4 which is now in position num 5:

```
iptables -D INPUT 5
```

## Credits
Janus background - Deep Ellum Janus, by Dan Colcer (Transylvania, Romania @dcolcerart) was painted in 2016.

Icons from https://icons8.com

Zephir-lang for making an awesome language!
https://zephir-lang.com/en

Name the show this is named from? ;-)