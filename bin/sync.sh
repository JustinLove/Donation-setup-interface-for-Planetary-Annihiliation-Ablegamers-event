s3cmd sync --acl-public --add-header="Cache-Control:max-age=600" dist/ s3://wondible-com-ablegamers-2017 
s3cmd modify --add-header="Cache-Control:max-age=86400" s3://wondible-com-ablegamers-2017/pa
