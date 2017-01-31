# Copyright (C) 2016 Tata Communications, Ltd. All rights reserved. 

# Deployment quirks

Before `cap staging deploy`, do these:

* replace <your-codecommit-key> with your uniq key in the `config/deploy.rb` file. **DO NOT COMMIT THIS CHAGE TO GIT!** After deploying, you can revert this.

* In the server, replace the codecommit key to yours in this file, `sdx_qm/repo/config`, in this line:
    url = ssh://RANDOMLUQ3JR7DMY9E@git-codecommit.us-east-1.amazonaws.com/v1/repos/SDX_v2_QuotaManager

And then only do `cap staging deploy`

If there is change in the application.yml file . Run the command cap production setup:upload_config.

Then deploy the app.

To check log go to current and type sudo tail -100f /var/log/sdx_qm.log.