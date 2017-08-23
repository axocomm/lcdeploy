# lcdeploy

Somewhat drama-free deployments.

## Rationale

This project aims to be a lightweight, easy-to-use deployment system
somewhere between a shell script/Rakefile and something like Chef or
Ansible. It's pretty much a sort of wrapper around shell commands.

I wanted to still be able to keep my deployments inside the project
repositories themselves but move away from giant Rakefiles and shell
commands.

## Installation

To install from source, just run

    gem build lcdeploy.gemspec
    gem install gemspec-<version>.gem

The `lcdeploy` executable should now be available for use in projects.

If this gets anywhere, it will hopefully end up somewhere for sticking
into a `Gemfile`. But for now, this works.

## How to Use

### `lcdfile`

An `lcdfile` just contains the steps to take for deploying your
application. It is basically just Ruby code, e.g.:

``` ruby
configure from_file: 'config.json'

repo_dir = '/home/deploy/lambda-codes-snippets'

create_directory '/www/snippets.lambda.codes', user: 'deploy', mode: 0655

clone_repository 'git@gitlab.com:axocomm/snippets.lambda.codes',
                 to: repo_dir,
                 user: 'deploy',
                 branch: 'dev'

build_docker_image 'lambda-snippets', tag: 'dev', path: repo_dir

run_docker_container 'lambda-snippets',
                     image: 'lambda-snippets',
                     tag: 'staging',
                     ports: [5000, [123, 456]],
                     volumes: [[Dir.pwd, '/app']]

put_file "#{repo_dir}/resources/config.json",
         source: 'config.json'
```

With an `lcdfile` populated, you can now run `lcdeploy preview` to get
a list of commands that will be run. `lcdeploy deploy` will actually
execute the deployment.

### Configuration

Configuration is done either right in the `lcdfile` or via a
JSON/(soon YAML) file. Right now this just contains SSH connection
information but may be extended to support more.

To configure in the `lcdfile`, just call the `configure` function with
a hash of options, e.g.:

``` ruby
configure ssh_host: 'winds', ssh_user: 'deploy', ssh_key: '~/.ssh/id_rsa.pub'
```

You can also pass in `from_file` to read from a JSON file:

``` json
{
  "ssh_host": "winds",
  "ssh_user": "deploy",
  "ssh_key": "~/.ssh/id_rsa.pub"
}
```

## Steps

Steps are pretty self-explanatory. They will typically follow the form

``` ruby
step_name '<label argument>' foo: 'bar', baz: 'quux'
```

The `label argument` right now maps to one of the required parameters
for the step. Eventually this will probably move to being an actual
label (also serving as a default value for a target directory,
filename, etc.).

The following are the currently-supported steps and their parameters.

### `put_file`

This copies a local file to the remote server using SCP.

#### Parameters

- `target` (label argument): the remote target
- `source`: the local source file

#### Example

``` ruby
put_file '/home/deploy/foo.bar/config.yml', source: 'config.prod.yml'
```

would copy `config.prod.yml` to
`<ssh_user>@<ssh_host>:/home/deploy/foo.bar/config.yml`.
