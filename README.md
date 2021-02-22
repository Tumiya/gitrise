# Gitrise 

A Bitrise trigger in pure `bash` 🎉!


## Usage
1. ```chmod +x gitrise.sh```  
2. ```gitrise.sh [options]```  

```
Usage: gitrise [options]

[options]
  -w, --workflow      <string>    Bitrise Workflow
  -b, --branch        <string>    Git Branch
  -t, --tag           <string>    Git Tag
  -e, --env           <string>    List of environment variables in the form of key1:value1,key2:value2
  -a, --access-token  <string>    Bitrise access token
  -s, --slug          <string>    Bitrise project slug
  -v, --version                   App version
  -d, --debug                     Debug mode enabled
  -h, --help                      Print this help text
```

## API Reference

Please see [here](https://api-docs.bitrise.io/#/) for Bitrise API Reference 

## Contributing

Bug reports and suggestions for improvement are always welcome! Pull requests are also accepted!

If you are interested in adding functionality through a pull request, please open a new issue so that we have the chance to discuss it first.

Before opening a PR, please make sure you have gone through the following steps:

 * linted the scripts you have touched using [ShellCheck](https://github.com/koalaman/shellcheck)
 * added tests for your changes

To run the unit tests, use the following command in the project directory
```bash
./tests/test_runner
```

After testing your changes, open a pull request to merge your branch into the **develop** branch.


## License
This software is available as open source under the terms of the MIT License. A copy of this license is included in the file [LICENSE](https://github.com/azohra/gitrise.sh/blob/develop/LICENSE).
