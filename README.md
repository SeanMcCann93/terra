# terra

Welcome to 'terra'V2, this version has a cleaner look and debug feature. This application has been developed to enable users a local way to swap and manage different versions of Terraform.

To use this, follow the setup instructions bellow.

### Setup

Copy and paist this code.

```
git clone https://github.com/SeanMcCann93/terra.git \
&& cd ./terra \
&& bash addTERRA.sh \
&& cd ./.. \
&& rm -rf ./terra \
&& terra
```

The above will install 'terra' as an executable. Try 'terra -h' for a list of actionable commands.  

If you need to debug what is happening you can use `--debug`

To hide the logo, use `terra --logo-toggle` to display the required command or just use `export terraLogoDisp="false"`.
