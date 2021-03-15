# Gitrise 
[![Release](https://img.shields.io/github/release/azohra/gitrise.sh.svg)](https://github.com/azohra/gitrise.sh/releases)
[![Mainline Status](https://github.com/azohra/gitrise.sh/workflows/CI-workflow/badge.svg)](https://github.com/azohra/gitrise.sh/actions?query=branch%3Adevelop)

A Bitrise trigger in pure `bash`!

![](docs/images/gitrise.png)

## Usage
To use Gitrise, all you need is the `gitrise.sh` script. There are four arguments that you have to pass to the script for a successful run:  
 
 ```gitrise.sh -a token -s project_slug -w workflow [-b branch|-t tag|-c commit]```  

Gitrise supports all the building capabilities of Bitrise including commit, tag, branch. In the usage guide above, these options are shown with `[-b branch|-t tag|-c commit]`. For building purposes, however, you may only pass one of these building options as Bitrise will only use one of them in this priority order: commit, tag, branch. This means, if you pass both a commit and a tag, Bitrise will use the commit for building. 

The complete Gitrise usage guide can be found below:

```
Usage: gitrise.sh [-d] [-e] [-h] [-T] [-v]  -a token -s project_slug -w workflow [-b branch|-t tag|-c commit] 

[options]
  -a, --access-token  <string>    Bitrise access token
  -b, --branch        <string>    Git branch
  -c, --commit        <string>    Git commit hash
  -d, --debug                     Debug mode enabled
  -e, --env           <string>    List of environment variables in the form of key1:value1,key2:value2
  -h, --help                      Print this help text
  -s, --slug          <string>    Bitrise project slug
  -T, --test                      Test mode enabled
  -t, --tag           <string>    Git tag
  -v, --version                   App version
  -w, --workflow      <string>    Bitrise workflow
```

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
