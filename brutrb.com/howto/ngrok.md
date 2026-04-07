# How to Use ngrok

[ngrok](https://ngrok.com/) allows you to serve your dev environment on the
public internet. This may sound like a Bad Idea, but it's useful to testing
webhooks or demoing what you are working on.

To server your Brut app on ngrok:

1. Sign up for ngrok - you can do everything here witih the free plan.
2. Get your authtoken, which is available [from the Dashboard](https://dashboard.ngrok.com/get-started/your-authtoken).
3. Stop your dev environment and edit `Dockerfile.dx` to install ngrok.  Locate
   the section that sets up the local user. There is a large comment explaining
   this and the first directive will be something like `ARG user_uid=xxxxx`.
   **Before** this directive, add (this is based on [ngrok's documentation](https://dashboard.ngrok.com/get-started/setup/linux):

   ```
   RUN curl -sSL https://ngrok-agent.s3.amazonaws.com/ngrok.asc | \
         tee /etc/apt/trusted.gpg.d/ngrok.asc >/dev/null && \
       echo "deb https://ngrok-agent.s3.amazonaws.com bookworm main" | \
         tee /etc/apt/sources.list.d/ngrok.list && \
       apt update && \
       apt install --yes ngrok
   ```
4. Rebuild your dev environment with `dx/build`.
4. Start your dev environment and set up your app:
   1. `dx/start`
   2. [in another termianl] `dx/exec bin/setup`
5. Make your authtoken available inside your docker container
   1. `dx/exec ngrok config add-authtoken <<YOUR_AUTHTOKEN>>`
6. Add this line to `Procfile.development`:

   ```
   ngrok: ngrok http 6502
   ```
7. Allow ngrok's domain to be served.  In `app/src/app.rb`, find the
   `initialize` method of `App` and add this at the end:

   ```ruby
   Brut.container.override("local_hostname",".ngrok-free.dev")
   ```

Now, when you run `dx/exec bin/dev` your app is on the public internet.  Go to
the (confusingly titled) [Agents page](https://dashboard.ngrok.com/agents) to
see your app. You'll need to click into it to find the URL.

To always use that URL, modify `Procfile.development`:

```
ngrok: ngrok http 6502 --url <<whatever that url was>>>
```

Brut doesn't provide more automation than this, but you can make this easier by
modifying `bin/setup` as needed.
