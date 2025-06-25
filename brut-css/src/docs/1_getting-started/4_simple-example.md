## Example

Let's make a button toolbar thingy.  We have three buttons: "Send Now", "Send Later", and "Cancel".  We aren't sure how we
want them to look.


First, write HTML:

    <button>
      Send Now
    </button>
    <button>
      Send Later
    </button>
    <button>
      Cancel
    </button>


Looks ok, actually, but we want the buttons to be different and bigger and more buttony.

<button>
  Send Now
</button>
<button>
  Send Later
</button>
<button>
  Cancel
</button>

Let's give them some padding, custom borders, and border radius:


    <button class="ph-3 pv-2 ba bc-black br-3">
      Send Now
    </button>
    <button class="ph-3 pv-2 ba bc-black br-3">
      Send Later
    </button>
    <button class="ph-3 pv-2 ba bc-black br-3">
      Cancel
    </button>

<button class="ph-3 pv-2 ba bc-black br-3">
  Send Now
</button>
<button class="ph-3 pv-2 ba bc-black br-3">
  Send Later
</button>
<button class="ph-3 pv-2 ba bc-black br-3">
  Cancel
</button>

They need to be be bigger, so let's add one step more padding all around, use a bigger font and, while we're at it, use some
color to differentiate. "Send Now" is what our growth-hacking engagement managers want people to click, so that will be
green, with "Send Later" in blue.  Of course, cancel is the universal sign of danger: red.

    <button class="ph-4 pv-3 f-3 ba bc-green-300 br-3 bg-green-800 green-400">
      Send Now
    </button>
    <button class="ph-4 pv-3 f-3 ba bc-blue-300 br-3 bg-blue-800 blue-400">
      Send Later
    </button>
    <button class="ph-4 pv-3 f-3 ba bc-red-300 br-3 bg-red-800 red-400">
      Cancel
    </button>

Not bad!

<button class="ph-4 pv-3 f-3 ba bc-green-300 br-3 bg-green-800 green-400">
  Send Now
</button>
<button class="ph-4 pv-3 f-3 ba bc-blue-300 br-3 bg-blue-800 blue-400">
  Send Later
</button>
<button class="ph-4 pv-3 f-3 ba bc-red-300 br-3 bg-red-800 red-400">
  Cancel
</button>

Our green text needs more contrast, but our marketing team wants it to stand out even more, so we'll inverse the colors. Let's also adjust the design so that the two send buttons appear to be related, and cancel is a bit unrelated.  We'll make the send buttons look like two sides of one button.

    <button class="ph-4 pv-3 f-3 ba bc-green-300 br-left-3 ma-0 bg-green-300 green-800">
      Send Now
    </button>
    <button class="ph-4 pv-3 f-3 ba bc-blue-300 br-right-3 ma-0 bg-blue-800 blue-400">
      Send Later
    </button>
    <button class="ph-3 pv-2 f-2 ba bc-red-300 br-3 ml-4 bg-red-800 red-400">
      Cancel
    </button>

<button class="ph-4 pv-3 f-3 ba bc-green-300 br-left-3 ma-0 bg-green-400 green-900">
  Send Now
</button>
<button class="ph-4 pv-3 f-3 ba bc-blue-300 br-right-3 ma-0 bg-blue-800 blue-400">
  Send Later
</button>
<button class="ph-3 pv-2 f-2 ba bc-red-300 br-3 ml-4 bg-red-800 red-400">
  Cancel
</button>

It's not quite right. We want our Send buttonsd touching, and the cancel button is now too far away.  Let's use flexbox.
We'll also make the cancel button "pointier" but reducing the border radius.

    <div class="flex items-center justify-center">
      <button class="ph-4 pv-3 f-3 ba bc-green-300 br-left-3 ma-0 bg-green-400 green-900">
        Send Now
      </button>
      <button class="ph-4 pv-3 f-3 ba bc-blue-300 br-right-3 blw-0 ma-0 bg-blue-800 blue-400">
        Send Later
      </button>
      <button class="ph-3 pv-2 f-2 ba bc-red-300 br-1 ml-2 bg-red-800 red-400">
        Cancel
      </button>
    </div>

<div class="flex items-center justify-center">
  <button class="ph-4 pv-3 f-3 ba bc-green-300 br-left-3 ma-0 bg-green-400 green-900">
    Send Now
  </button>
  <button class="ph-4 pv-3 f-3 ba bc-blue-300 br-right-3 blw-0 ma-0 bg-blue-800 blue-400">
    Send Later
  </button>
  <button class="ph-3 pv-2 f-2 ba bc-red-300 br-1 ml-2 bg-red-800 red-400">
    Cancel
  </button>
</div>

Not bad!  Notice how we used the various scales of the classes to quickly audition and tweak aspects of the design.  We
didn't have to agonize of pixels or points.

