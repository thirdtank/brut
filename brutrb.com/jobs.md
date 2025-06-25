# Background Jobs

Brut provides little direct support for background jobs. Currently, Brut recommends Sidekiq, since it is
battle-tested, well-supported, and open source.

When you set up your Brut app, it should ask if you want Sidekiq support and add the necessary configuraiton.

It will expect jobs in `app/src/back_end/jobs`.

> [!WARNING]
> The way Sidekiq is configured with Brut is effective and reliable, but it is complex.  It currently
> involves several moving parts to make it work properly.  This will be an area for improvement.


