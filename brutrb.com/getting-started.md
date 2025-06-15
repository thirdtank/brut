# Getting Started

To make a new app with Brut, you'll need to clone a template app, initialize it, then set up your dev environment.

## Clone the App Template

To get started, clone the Brut app template:

```
> git clone https://github.com/thirdtank/brut-app-template your-app-name
```

## Init Your App

The template includes `init`, which will ask you a few questions to get everything set up.

```
> cd your-app-name
> ./init
```

You'll need to provide four pieces of info:

* Your app's name, suitable has a hostname or identifier
* A prefix for your app's externalizable ids
* A prefix for your app's custom elements
* An organization name, needed for deployment

::: tip
Choose your app's name wisely, however everything else can be easily changed later, so don't stress!
:::

## Set Up Your Dev Environment

Brut includes a dev environment based on Docker.

1. [Install Docker](https://docs.docker.com/get-started/get-docker/)
2. Build Your images

   ```
   > dx/build
   ```
3. Start up the environment

   ```
   > dx/start
   ```
4. Install gems and modules for your app. In another terminal:

   ```
   > dx/exec bin/setup
   ```

Now, you're ready to go

## Run the App

```
> dx/exec bin/dev
```

You can now visit your app at `localhost:6502`

## Now Build The Rest of Your App 🦉

You can [follow the tutorial](/tutorial), check out the [conceptual overview](/overview), or dive straight into the API docs.
