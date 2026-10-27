// EclipseOS system defaults for the Debian Firefox ESR build.
//
// This file is read before the user profile is created. It points the browser
// at the local EclipseOS start page and turns off first-run, sponsored and
// telemetry surfaces. The upstream Firefox names, icons and update channel are
// left intact: EclipseOS does not present Firefox as its own browser.

// Keep the Debian defaults that are still appropriate.
pref("extensions.update.enabled", true);
pref("intl.locale.requested", "");
pref("browser.shell.checkDefaultBrowser", false);
pref("media.gmp-gmpopenh264.enabled", false);
pref("browser.newtabpage.enhanced", false, sticky);
pref("datareporting.healthreport.uploadEnabled", false);

// EclipseOS start page and first-run behaviour.
pref("browser.startup.page", 1);
pref("browser.startup.homepage", "file:///usr/share/eclipseos/browser/home.html");
pref("browser.startup.homepage_override.mstone", "ignore");
pref("browser.newtabpage.enabled", false);
pref("browser.aboutwelcome.enabled", false);
pref("browser.aboutwelcome.showOnFirstRun", false);
pref("browser.tabs.warnOnClose", false);

// No search suggestions, sponsored tiles or recommendation feeds.
pref("browser.urlbar.suggest.searches", false);
pref("browser.search.suggest.enabled", false);
pref("browser.search.suggest.enabled.private", false);
pref("browser.discovery.enabled", false);
pref("browser.newtabpage.activity-stream.showSponsored", false);
pref("browser.newtabpage.activity-stream.showSponsoredTopSites", false);
pref("browser.newtabpage.activity-stream.feeds.topsites", false);
pref("browser.newtabpage.activity-stream.feeds.section.topstories", false);
pref("browser.newtabpage.activity-stream.feeds.snippets", false);
pref("browser.urlbar.suggest.quicksuggest.sponsored", false);
pref("browser.urlbar.suggest.quicksuggest.nonsponsored", false);

// Live media has no persistent telemetry identity. Keep all reporting off.
pref("toolkit.telemetry.enabled", false);
pref("toolkit.telemetry.unified", false);
pref("toolkit.telemetry.archive.enabled", false);
pref("datareporting.policy.dataSubmissionEnabled", false);
pref("datareporting.healthreport.uploadEnabled", false);
pref("app.shield.optoutstudies.enabled", false);
pref("app.normandy.enabled", false);
