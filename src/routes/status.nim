import asyncdispatch, strutils, sequtils, uri, options

import jester, karax/vdom

import router_utils
import ".."/[types, formatters, api]
import ../views/[general, status]

export uri, sequtils, options
export router_utils
export api, formatters
export status

proc createStatusRouter*(cfg: Config) =
  router status:
    get "/@name/status/@id/?":
      cond '.' notin @"name"
      let prefs = cookiePrefs()

      if @"scroll".len > 0:
        let replies = await getReplies(@"id", getCursor())
        if replies.content.len == 0:
          resp Http404, ""
        resp $renderReplies(replies, prefs, getPath())

      let conv = await getTweet(@"id", getCursor())
      if conv == nil:
        echo "nil conv"

      if conv == nil or conv.tweet == nil or conv.tweet.id == 0:
        var error = "Tweet not found"
        if conv != nil and conv.tweet != nil and conv.tweet.tombstone.len > 0:
          error = conv.tweet.tombstone
        resp Http404, showError(error, cfg)

      var
        title = pageTitle(conv.tweet)
        ogTitle = pageTitle(conv.tweet.profile)
        desc = conv.tweet.text
        images = conv.tweet.photos
        video = ""

      if conv.tweet.video.isSome():
        images = @[get(conv.tweet.video).thumb]
        video = getVideoEmbed(cfg, conv.tweet.id)
      elif conv.tweet.gif.isSome():
        images = @[get(conv.tweet.gif).thumb]
        video = getPicUrl(get(conv.tweet.gif).url)
      elif conv.tweet.card.isSome():
        let card = conv.tweet.card.get()
        if card.image.len > 0:
          images = @[card.image]
        elif card.video.isSome():
          images = @[card.video.get().thumb]


      let rss = "/$1/status/$2/rss" % [@"name", @"id"]
      let html = renderConversation(conv, prefs, getPath() & "#m")
      resp renderMain(html, request, cfg, prefs, title, desc, ogTitle,
                      images=images, video=video, rss=rss)

    get "/@name/@s/@id/@m/?@i?":
      cond @"s" in ["status", "statuses"]
      cond @"m" in ["video", "photo"]
      redirect("/$1/status/$2" % [@"name", @"id"])

    get "/@name/statuses/@id/?":
      redirect("/$1/status/$2" % [@"name", @"id"])

    get "/i/web/status/@id":
      redirect("/i/status/" & @"id")
