# Managing Secrets in the Dev Environment

Often, you need API keys like GitHub or Heroku tokens in order to perform development tasks. These should not be checked into version
control, however you can still manage them.

## Feature - API Keys

* Developers need do use the Heroku command-line app inside the dev container.
* Develoeprs do not want to have to perform a daily, browser-based authentication via `heroku auth:login`

### Recipe

The file `dx/bash_customizations.local` is set up for exactly this.  It is not checked into version control (see your `.gitignore`), and it
is included when the development environment is built.

```bash
# dx/bash_customizations.local
HEROKU_API_KEY=xxxxxx
```

When you change this file, you must rebuild your dev environment:

1. `Ctrl-C` wherever you ran `dx/start`
2. `dx/build`
3. `dx/start`
4. `dx/exec bash`, then `bin/setup`, then continue where you left off

#### How This Works

Here is a snippet of how this works.  In the first `RUN` directlive, the non-root user is created. When that is completed, `~/.profile` and
`~/.bashrc` are modified to source both `bash_customizations` (per-project customizations that should **not** contain secrets) and
`bash_customizations.local`, which is the file we are discussing.

After that, the files are copied into the image via the `COPY` directives.

```dockerfile
# Snippet from Dockerfile.dx
RUN useradd --uid ${user_uid} --gid ${user_gid} --groups ${sadly_user_must_be_added_to_root}${docker_gid} --create-home --home-dir /home/appuser appuser && \
    echo ". ~/.bash_customizations" >> /home/appuser/.profile && \
    echo ". ~/.bash_customizations.local" >> /home/appuser/.profile && \
    echo ". ~/.bash_customizations" >> /home/appuser/.bashrc && \
    echo ". ~/.bash_customizations.local" >> /home/appuser/.bashrc

COPY --chown=appuser:${user_gid} dx/show-help-in-app-container-then-wait.sh /home/appuser
COPY --chown=appuser:${user_gid} dx/bash_customizations /home/appuser/.bash_customizations
COPY --chown=appuser:${user_gid} dx/bash_customizations.local /home/appuser/.bash_customizations.local
```

> [!WARNING]
> The resulting image **will** contain the secrets from `bash_customizations.local`, so it's
> **very important** you never push that image to a regsitry.

## Feature - SSH Keys

* You need an SSH key in order to push to GitHub from the dev container
* You do not want to creata new key every time

### Recipe

Ultimately, you want the SSH key to be copied into the container and set up as if you'd created the key there.  The recipe below is an
example of how you could do this, and should demonstrate the various seams in Brut's dev environment to allow you to craft it how you like.

1. Choose a directory in the project where each developer will store their keys. **This directory should be excluded from version control**

   ```
   mkdir dx/credentials
   echo "/dx/credetials" >> .gitignore
   ```

2. Assuming you create an SSH key already, place `id_ed25519` (private key) and `id_ed25519.pub` (public key) into `dx/credentials`.
3. Create `dx/credentials/known_hosts` using `id_ed25519.pub`:

   ```
   github.com ssh-ed25519 «key from id_ed25519.pub here»
   ```
4. Your dev container will have access to `dx/credentials` already, so you can use `bin/setup` to copy them to the right place. How
   you do this depends on how complicated you want to get.  You can examine Brut's `bin/setup` to see how it manages it.  You will
   see that ti uses `ssh-agent` to avoid requiring the passcode every time, and that it uses `chmod` to make sure the SSH
   directories are the right permissions.

> [!WARNING]
> The resulting image **will** contain your SSH key, so it's
> **very important** you never push that image to a regsitry.


This recipe is scant on details, since each credential is highly specific. The key points to know are that you can store information in the
project, but not checked in, then rely on that information being available to `bin/setup` inside the container.
