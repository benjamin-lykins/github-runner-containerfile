## Intro
Nothing too wild in here, looking to test running GitHub Actions Runners using Podman, there is documentation out there to run on Docker, thought I spin up something for Podman. 

The image building and `start.sh` was heavily borrowed from : 
- Alessandro Baccini --- [How to containerize a GitHub Actions self-hosted runner](https://baccini-al.medium.com/how-to-containerize-a-github-actions-self-hosted-runner-5994cc08b9fb)
- Michael Herman --- [Deploying Self-Hosted GitHub Actions Runners with Docker](https://testdriven.io/blog/github-actions-docker/)

Deviation from blogs: 
- Using podman
- Added variables for RUNNER_IMAGE and RUNNER_ARCH. Modifies what release to download from GitHub. 
  - RUNNER_IMAGE: Could be used for Windows/macOS/Linux, Containerfile and `start.sh` would need to be to support macOS and Windows.
  - RUNNER_ARCH: Primariy the CPU architecture - x64, arm, arm64
- Updated user to runner from docker to make it more specific to GitHub Actions runner.
- In the `start.sh` script
  - Updated the config.sh to run unattened and ephemeral. 


```bash
./config.sh --url https://github.com/${REPOSITORY} --token ${REG_TOKEN} --unattended
```

## Build Image

Currently building as a arm64 linux image, if needing the runner to run on x64, update the variables in the Containerfile.
I have not messed with macOS or Windows, but the `start.sh` file would need to be heavily modified. 

```dockerfile
ARG RUNNER_VERSION="2.315.0"
# Only linux in this case, Windows containers should be possible, but not tested.
ARG RUNNER_IMAGE="linux"
# Either x64 or arm64 or arm
ARG RUNNER_ARCH="arm64"

To build the image: 

```bash
podman build -t actions-runner .
```

Should have an output similar to this when completed: 

```bash
Successfully tagged localhost/actions-runner:latest
5c982051b1c07dc67c41bcd5fb36ab3818f8bbb89dea63fe169d07d2d9d49953
```

Run the image: 

To run the image you will need two environment variables, you may also need to specify a different image to use. Mine was still local when writing this up:

```bash
podman run \
--detach \
--env REPO=$REPO \
--env TOKEN=$TOKEN \
localhost/actions-runner
```
If all goes well you should see in your GitHub Actions Runners the following: 
![image](https://github.com/benjamin-lykins/github-runner-containerfile/assets/91494226/35a776fe-8162-4582-920a-d0733d9acc3f)

The name is from the containerid: 

```bash
CONTAINER ID  IMAGE                            COMMAND     CREATED        STATUS        PORTS       NAMES
b032557bddcc  localhost/actions-runner:latest              8 seconds ago  Up 8 seconds              modest_burnell
```

If you want a more custom name, you would need to update when running `config.sh` in the `start.sh` script: 

```bash
./config.sh --help                                                                                                                                                                                 

Commands:
 ./config.sh         Configures the runner
 ./config.sh remove  Unconfigures the runner
 ./run.sh            Runs the runner interactively. Does not require any options.

Options:
 --help     Prints the help for each command
 --version  Prints the runner version
 --commit   Prints the runner commit
 --check    Check the runner's network connectivity with GitHub server

Config Options:
 --unattended           Disable interactive prompts for missing arguments. Defaults will be used for missing options
 --url string           Repository to add the runner to. Required if unattended
 --token string         Registration token. Required if unattended
 --name string          Name of the runner to configure (default ****)
 --runnergroup string   Name of the runner group to add this runner to (defaults to the default runner group)
 --labels string        Custom labels that will be added to the runner. This option is mandatory if --no-default-labels is used.
 --no-default-labels    Disables adding the default labels: 'self-hosted,OSX,Arm64'
 --local                Removes the runner config files from your local machine. Used as an option to the remove command
 --work string          Relative runner work directory (default _work)
 --replace              Replace any existing runner with the same name (default false)
 --pat                  GitHub personal access token with repo scope. Used for checking network connectivity when executing `./run.sh --check`
 --disableupdate        Disable self-hosted runner automatic update to the latest released version`
 --ephemeral            Configure the runner to only take one job and then let the service un-configure the runner after the job finishes (default false)

Examples:
 Check GitHub server network connectivity:
  ./run.sh --check --url <url> --pat <pat>
 Configure a runner non-interactively:
  ./config.sh --unattended --url <url> --token <token>
 Configure a runner non-interactively, replacing any existing runner with the same name:
  ./config.sh --unattended --url <url> --token <token> --replace [--name <name>]
 Configure a runner non-interactively with three extra labels:
  ./config.sh --unattended --url <url> --token <token> --labels L1,L2,L3
```

```bash
./config.sh --url https://github.com/${REPOSITORY} --token ${REG_TOKEN} --unattended --ephermeral
```


