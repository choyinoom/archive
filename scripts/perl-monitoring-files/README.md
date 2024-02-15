# File Monitoring Perl Script

This Perl script is designed for monitoring files that should have been sent and removed from a specified directory within a specific time frame. The script performs the following tasks:

**1. File Discovery and Filtering:**

* Traverses a directory structure rooted at "/home/choyinoom/" using File::Find.
* Filters files with ".txt" or ".dat" extensions.
* Skips certain directories based on predefined conditions.

**2. File Filtering Criteria:**

* Checks if files meet specific conditions, including being modified within the last hour and not on a skiplist.

**3.Skiplist Function:**

* Skips files based on patterns and current time conditions.

**Notification Generation and Sending:**

* Formats information about qualifying files (name and modification time) into a notification string.
* Sends an HTTP POST request to "http://my-custom-alarm.com/call" with a JSON payload containing file details.

## Usage

* Execute the script to monitor files and receive alarms for files that haven't been sent and remain in the directory.

```bash
# crontab -l
10,30,50 * * * * perl /home/choyinoom/monitoring_files.pl
```
