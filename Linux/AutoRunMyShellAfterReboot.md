# In the file you put in /etc/init.d/ you have to set it executable with
chmod +x /etc/init.d/start_my_app

# if this does not run you have to create a symlink to /etc/rc.d/
ln -s /etc/init.d/start_my_app /etc/rc.d/

# And don't forget to add on top of that file:
#!/bin/sh