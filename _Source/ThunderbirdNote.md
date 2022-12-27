How to get log from Thunderbird

https://wiki.mozilla.org/MailNews:Logging#Windows


```bash
# For bash shell (the default shell on most GNU/Linux systems):
export MOZ_LOG=IMAP:5,timestamp
export MOZ_LOG_FILE=/tmp/imap.log
```

```bash
# For tcsh / csh (which is not as common):
setenv MOZ_LOG IMAP:5
setenv MOZ_LOG_FILE /tmp/imap.log
```
