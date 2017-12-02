/*
 * This is a service worker script which sw-precache will import,
 * to deal with caching of photos.
 *
 * This gets "included" in service-worker.js via an `importScripts`.
 * Note that it runs **in that context**, so we create a separate
 * context here with an immediately-executing function.
 */
'use strict';

(function () {
    var cacheName = "photos";

    // So, we're matching all Drupally-provided files here. In theory, this is
    // a bit over-broad, since we could limit it to our actual backend. But, we
    // don't actually know that here, and it probably won't cause any trouble --
    // if it's not in the cache, we'll just try to fetch it.
    var matchUrl = /\/sites\/default\/files\//;

    var uploadCache = "photos-upload";
    var uploadUrl = /\/cache-upload\/images/;

    self.addEventListener('fetch', function (event) {
        if ((event.request.method === 'GET') && matchUrl.test(event.request.url)) {
            var response =
                caches.open(
                    cacheName
                ).then(function (cache) {
                    return cache.match(event.request.url).then(function(response) {
                        if (response) {
                            return response;
                        } else {
                            throw Error('Image was not cached.');
                        }
                    });
                }).catch(function(e) {
                    // We're relying on the Elm app itself to manage the cache,
                    // so we don't store the fetched item in the cache ... we
                    // just fall back to getting it. In fact, this will be the
                    // code path when we **populate** the cache in Elm.
                    return fetch(event.request);
                });

            event.respondWith(response);
        }

        if ((event.request.method === 'POST') && uploadUrl.test(event.request.url)) {
            event.respondWith(
                caches.open(
                    uploadCache
                ).then (function (cache) {
                    // TODO: We'll need to generate a unique URL here ...
                    var url = "/cache-upload/images/" + "something";

                    // We want to extract the file that got sent, and store it in a way
                    // that a request will hand it back.
                    var eventualRequest = new Request (url, {
                        method: "GET"
                    });

                    return event.request.formData().then(function (formData) {
                        // The body of our eventual response ... extract the image from the
                        // request.
                        var body = formData.get("file");

                        // So, this is the response we'll eventually send, when the actual
                        // file is requested ...
                        var eventualResponse = new Response (body, {
                            status: 200,
                            statusText: "OK",
                            headers: {
                                'Content-Length': body.size,
                                'Content-Type': body.type
                            }
                        });

                        return cache.put(eventualRequest, eventualResponse).then(function () {
                            var responseText = JSON.stringify({
                                url: url
                            });

                            return new Response (responseText, {
                                status: 201,
                                statusText: "Created",
                                headers: {
                                    Location: url
                                }
                            });
                        });
                    });
                })
            );
        }
    });
})();
