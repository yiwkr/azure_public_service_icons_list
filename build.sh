#!/bin/bash

# logger
function log() { { [[ -p /dev/stdin ]] && { printf "%s " "$*"; cat -; } || echo -e "$@"; } >&2; }
function errorlog() { log ERROR "$@"; }
function debuglog() { [[ -n "$DEBUG" ]] && log DEBUG "$@"; }
function infolog() { log INFO "$@"; }

function usage() {
cat <<EOM
Usage: build.sh [-h|--help] [-d|--debug]

This script builds html text and print it to stdout.

Optional arguments
  -h, --help     show this messages
  -d, --debug    enable debug mode
EOM
}

# parse arguments
args=()
for _ in "$@"; do
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    -d|--debug)
      DEBUG=1
      ;;
    *)
      [[ -n "$1" ]] && args+=("$1")
      ;;
  esac
  shift
done

if [[ "${#args[@]}" -gt 0 ]]; then
  errorlog "unknown arguments:" "${args[@]}"
  exit 1
fi

if [[ -n "$DEBUG" ]]; then
  debuglog "debug mode is enabled"
fi

# constants
ICONS_DIR="${ICONS_DIR:-Azure_Public_Service_Icons/Icons}"
ICONS_DIR="${ICONS_DIR%/}"  # ensure trailing slash removed

# icons directory validation
if [[ ! -d "$ICONS_DIR" ]]; then
  errorlog "Icons directory does not exist (please set \"path/to/Azure_Public_Service_Icons/Icons\" to ICONS_DIR environment variable)"
  exit 1
fi

# get service icon files and service categories
infolog find svg files from "$ICONS_DIR"
SVG_FILES="$(find "$ICONS_DIR" -type f -name '*.svg')"
SERVICE_CATEGORIES="$(echo "$SVG_FILES" | sed -E "s;$ICONS_DIR/;;" | sed 's;/.*;;' | sort -u)"

debuglog "SVG_FILES:\n$(echo "$SVG_FILES" | sed 's/^/- /')"
debuglog "SERVICE_CATEGORIES:\n$(echo "$SERVICE_CATEGORIES" | sed 's/^/- /')"

# capitalize each word
function capitalize() {
  cat -                        |
    sed 's/\<ai\>/AI/'         |  # ai -> AI
    sed 's/\<devops\>/DevOps/' |  # devops -> DevOps
    sed 's/\<iot\>/IoT/'       |  # iot -> IoT
    sed 's/\<[a-z]/\U&/g'         # word -> Word
}

function generate_style() {
  infolog generate style
  cat << EOM
body {
  box-sizing: border-box;
}

body, ul, li {
  margin: 0;
  padding: 0;
}

:focus-visible {
  outline: solid 2px #4bf;
}

.container {
  width: 90vw;
  margin: auto;
}

@media screen and (min-width: 1067px) { .container { width: 960px; } }

.jumbotron {
  display: flex;
  height: 100vh;
  padding: 0 5vw;
  background: #0078d4;
  justify-content: center;
  align-items: center;
  flex-direction: column;
}

.jumbotron h1 {
  font-size: xxx-large;
  color: #fff;
}

h2 {
  margin: 60px 0 16px 0;
}

h3 {
  border-bottom: solid 1px #ddd;
  margin: 40px 0 16px 0;
}

.service-search-container {
  display: flex;
  align-items: center;
  border-radius: 3px;
  border-top: solid 1px #666;
  border-right: solid 1px #ccc;
  border-bottom: solid 1px #ccc;
  border-left: solid 1px #666;
}

.service-search-label {
  font-size: small;
  margin: 0 8px;
}

.service-search-input,
.service-search-input:focus {
  width: 100%;
  border: none;
  line-height: 2rem;
  outline: 0;
}

.service-icons-list-container {
  min-height: 100vh;
}

.service-categories {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  list-style: none;
}

.service-categories li {
  width: 90vw;
}

h2 a, h3 a,
h2 a:link, h3 a:link,
h2 a:visited, h3 a:visited,
h2 a:hover, h3 a:hover,
h2 a:active, h3 a:active,
h2 a:focus, h3 a:focus {
  display: flex;
  align-items: center;
  gap: 8px;
  text-decoration: none;
  color: black;
}

h2 a:hover::after, h3 a:hover::after {
  content: "\1F517";
  font-size: 1rem;
}

.category-services-num {
  font-size: small;
  font-weight: lighter;
  color: #888;
}

.service-icons-list {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  list-style: none;
}

.service-icon-card {
  display: flex;
  background: inherit;
  width: 90vw;
  padding: 0;
  border: 0;
  border-radius: 8px;
  align-items: center;
  cursor: pointer;
  transition: all 0.1s;
}

@media screen and (min-width: 480px) { .service-categories li, .service-icon-card { width: 45vw; } }
@media screen and (min-width: 720px) { .service-categories li, .service-icon-card { width: 30vw; } }
@media screen and (min-width: 1067px) { .service-categories li, .service-icon-card { width: 240px; } }

.service-icon-card:hover {
  background: #edf7ff;
}

.service-icon-card:active {
  box-shadow: inset 2px 2px 2px 0 #0008;
}

.service-icon-card-content {
  display: flex;
  padding-right: 8px;
  align-items: center;
  text-align: left;
  transition: all 0.1s;
}

.service-icon-image {
  width: 64px;
  height: 64px;
  margin: 8px;
}

.service-icon-text-container {
  display: flex;
  flex-direction: column;
}

.service-icon-name {
  font-size: 0.9rem;
  cursor: text;
  user-select: text;
  overflow-wrap: anywhere;
}

.service-icon-keywords {
  font-size: x-small;
  color: #888;
}

.service-icon-card:active .service-icon-card-content {
  transform: translate(2px, 2px);
}

.footer {
  width: 100%;
  height: 120px;
  display: flex;
  justify-content: center;
  align-items: center;
  background: #eee;
  margin-top: 120px;
}

.footer span {
  font-size: small;
}
EOM
}

function generate_nav() {
  infolog generate nav
  for category in $SERVICE_CATEGORIES; do
    local escaped_category="${category// /-}"
    local capitalized_category="$(echo "$category" | capitalize)"
    cat << EOM
<li><a href="#service-icons-$escaped_category">$capitalized_category</a></li>
EOM
  done
}

function generate_icons_list() {
  infolog generate icons list: "$@"
  local category="$1"
  local escaped_category="${category// /-}"

  for icon_path in $(echo "$SVG_FILES" | grep "/$category/" | sort -t - -k 4); do
    local service_id="$(echo "$icon_path" | sed -E 's;^.*/([0-9]+)-icon-service-(.+)\.svg$;\1;')"
    local service_name="$(echo "$icon_path" | sed -E 's;^.*/([0-9]+)-icon-service-(.+)\.svg$;\2;' | sed 's/-/ /g')"
    local escaped_service_name="${service_name// /-}"
    local icon_data="$(base64 -w 0 "$icon_path")"
    local icon_title="$(echo "$icon_path" | sed "s;$ICONS_DIR/;;")"
    cat << EOM
<li>
  <button id="$escaped_category-$service_id-$escaped_service_name" class="service-icon-card" title="$icon_title">
    <div class="service-icon-card-content">
      <img class="service-icon-image" alt="$service_name" name="${icon_path##*/}" src="data:image/svg+xml;base64,$icon_data"/>
      <div class="service-icon-text-container"><span class="service-icon-name">${service_name}</span></div>
    </div>
  </button>
</li>
EOM
  done
}

function generate_icons_lists() {
  infolog generate icons lists
  for category in $SERVICE_CATEGORIES; do
    local escaped_category="${category// /-}"
    local capitalized_category="$(echo "$category" | capitalize)"
    local services_num="$(echo "$SVG_FILES" | grep -c "/$category/")"

    cat << EOM
<div class="service-category">
  <h3 id="service-icons-$escaped_category">
    <a href="#service-icons-$escaped_category">
      $(echo "$category" | capitalize)
      <span class="category-services-num">($services_num)</span>
    </a>
  </h3>
  <ul class="service-icons-list">
$(generate_icons_list "$category")
  </ul>
  <small><a href="#service-categories">カテゴリ一覧</a></small>
</div>
EOM
  done
}

function generate_footer() {
  infolog generate footer
  cat << EOM
      <span>This page was last modified on $(date "+%Y/%m/%d").</span>
EOM
}

function generate_javascript() {
  infolog generate javascript
  cat << 'EOM'
(function () {
  /* constants */
  const serviceSearchInputDebounceMillisec = 250;
  const searchWordSeparator = /\s+/;
  const servicesInfo = {
    "Application Security Groups": { keywords: ["ASG"] },
    "App Service Plans": { keywords: ["containers"] },
    "App Services": { keywords: ["containers", "Functions", "linux", "lightsail", "mobile", "mobile services", "mobile apps", "mobileapps", "mobileservices"] },
    "Automation Accounts": { keywords: ["powershell", "Powershell"] },
    "Azure Cosmos DB": { keywords: ["Document", "DocumentDB"] },
    "Azure Synapse Analytics": { keywords: ["privateendpoints", "endpoint"] },
    "Cloud Services (Classic)": { keywords: ["website", "web sites", "websites"] },
    "Connections": { keywords: ["VPN"] },
    "Event Hub Clusters": { keywords: ["Streaming platform", "Managed Kafka Ingestion Platform"] },
    "Event Hubs": { keywords: ["Streaming platform", "Managed Kafka Ingestion Platform"] },
    "Express Route Traffic Collector": { keywords: ["VPN"] },
    "ExpressRoute Circuits": { keywords: ["VPN"] },
    "ExpressRoute Direct": { keywords: ["VPN"] },
    "Function Apps": { keywords: ["app service", "webapp", "web application", "website", "web site"] },
    "Help and Support": { keywords: ["Resource health"] },
    "Immersive Readers": { keywords: ["AI", "Applied AI"] },
    "Intune": { keywords: ["Endpoint Manager", "Endpoint Management"] },
    "Language": { keywords: ["document classification", "multi-document summarization", "single-document summarization"] },
    "Local Network Gateways": { keywords: ["VPN"] },
    "Metrics Advisor": { keywords: ["AI", "Applied AI"] },
    "Network Interfaces": { keywords: ["NIC", "card", "interfaces", "network"] },
    "Network Security Groups": { keywords: ["NSG"] },
    "Power Platform": { keywords: ["mobile apps"] },
    "Private Link": { keywords: ["private endpoint"] },
    "Recovery Services Vaults": { keywords: ["Azure Site Recovery", "ASR"] },
    "SSH Keys": { keywords: ["sshkey"] },
    "Savings Plans": { keywords: ["compute"] },
    "Subscriptions": { keywords: ["resources", "resource groups"] },
    "Virtual Machine": { keywords: ["arc vm", "arc"] },
    "Virtual Network Gateways": { keywords: ["VPN"] },
  };

  /* global variables */
  const services = [];

  /* utils */
  const debounce = (f, wait) => {
    let timeoutID;
    return function (...args) {
      clearTimeout(timeoutID);
      timeoutID = setTimeout(() => f.apply(this, args), wait);
    };
  }

  /* get services */
  const serviceIconCards = document.getElementsByClassName("service-icon-card");
  for (const card of serviceIconCards) {
    const name = card.getElementsByTagName("span").item(0).innerText;
    services.push({
      name: name,
      elem: card,
    });
  }

  /* get url query strings */
  const params = new URLSearchParams(window.location.search);
  const searchString = params.get("q");

  /* add input listener for search */
  const serviceSearchInput = document.getElementById("service-search-input");
  const serviceSearchInputText = searchString || "";
  serviceSearchInput.value = serviceSearchInputText;
  serviceSearchInput.addEventListener("input", debounce((event) => {
    const serviceSearchInputText = event.target.value;

    /* update style.display */
    services.map((service) => {
      const searchWords = serviceSearchInputText.split(searchWordSeparator);
      const keywords = servicesInfo[service.name]?.keywords;
      const matchedKeywords = new Set();

      /* filter by search words */
      const serviceNameLowerCase = service.name.toLowerCase();
      const match = searchWords.every((word) => {
        const wordLowerCase = word.toLowerCase();
        const isServiceNameMatched = serviceNameLowerCase.includes(wordLowerCase);
        const filteredKeywords = wordLowerCase && keywords?.filter((keyword) => keyword.toLowerCase().includes(wordLowerCase));
        const isKeywordMatched = filteredKeywords && filteredKeywords.length > 0;
        if (!word || isServiceNameMatched || isKeywordMatched) {
          if (isKeywordMatched) {
            filteredKeywords.map((keyword) => matchedKeywords.add(keyword));
          }
          return true;
        }
        return false;
      });

      if (serviceSearchInputText === "" || match) {
        /* display */
        service.elem.style.display = "";

        /* add keywords element to service icon card */
        const addKeywordsElement = () => {
          if (!keywords) {
            return;
          }

          /* get keywords elements */
          const keywordsElements = service.elem.getElementsByClassName("service-icon-keywords");

          /* remove keywords elements if it already exists */
          for (const elem of keywordsElements) {
            elem.parentElement.removeChild(elem);
          }

          /* add keywords element */
          if (keywordsElements.length === 0 && matchedKeywords.size > 0) {
            const newSpan = document.createElement("span");
            newSpan.innerText = `Keywords: ${Array.from(matchedKeywords).join(', ')}`;
            newSpan.className = "service-icon-keywords";
            service.elem.getElementsByClassName("service-icon-text-container").item(0).appendChild(newSpan);
          }
        };
        addKeywordsElement();
      } else {
        /* hide */
        service.elem.style.display = "none";
      }
    });

    /* hide category having no service */
    const categories = document.getElementsByClassName("service-category");
    for (const category of categories) {
      const iconCards = Array.from(category.querySelectorAll(".service-icon-card"));
      if (iconCards.some((e) => e.style.display !== "none")) {
        category.style.display = "";

        /* update services num per category*/
        const categoryServicesNum = Array.from(iconCards)
          .filter((service) => service.style.display !== "none")
          .length;
        const categoryServicesNumElem = category.getElementsByClassName("category-services-num").item(0);
        categoryServicesNumElem.innerText = `(${categoryServicesNum})`;
      } else {
        category.style.display = "none";
      }
    }

    /* update url query string */
    const updateUrlQueryString = ({url}) => {
      if (serviceSearchInputText === searchString) {
        return;
      }
      const newUrl = new URL(url);
      const tmpParams = newUrl.searchParams;
      tmpParams.set("q", serviceSearchInputText);
      newUrl.search = tmpParams.toString();
      window.history.replaceState(null, "", newUrl.toString());
    };
    updateUrlQueryString({url: window.location.href});
  }, serviceSearchInputDebounceMillisec));

  if (searchString) {
    serviceSearchInput.dispatchEvent(new Event("input"));
  }

  /* add click event listener to copy image */
  for (const service of services) {
    service.elem.addEventListener("click", (event) => {
      navigator.clipboard.writeText(service.name);
      event.preventDefault();
    });
  }
})()

EOM
}

########
# main
########

OLD_IFS="$IFS"
IFS=$'\n'

cat << EOM
<!DOCTYPE html>
<html lang="ja">

<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width,initial-scale=1" />
  <title>Azure Public Service Icons List</title>
  <style>
$(generate_style)
  </style>
</head>

<body>
  <header>
    <div class="jumbotron">
      <h1>Azure Public Service Icons List</h1>
    </div>
  </header>

  <div class="container">
    <h2 id="overview"><a href="#overview">Overview</a></h2>
    <p>
      <a href="https://learn.microsoft.com/ja-jp/azure/architecture/icons/">https://learn.microsoft.com/ja-jp/azure/architecture/icons/</a> から入手したアイコンをもとに作成した一覧です。
    </p>

    <nav>
      <h2 id="service-categories"><a href="#service-categories">Service Categories</a></h2>
      <ul class="service-categories">
$(generate_nav)
      </ul>
    </nav>

    <main>
      <h2 id="service-icons"><a href="#service-icons">Service Icons</a></h2>
      <div class="service-search-container">
        <label class="service-search-label" for="service-search-input">&#x1F50D;</label>
        <input class="service-search-input" type="text" id="service-search-input" name="service-search-input" placeholder="Filter services" />
      </div>
      <div class="service-icons-list-container">
$(generate_icons_lists)
      </div>
    </main>
  </div>

  <footer>
    <div class="footer">
$(generate_footer)
    </div>
  </footer>

  <script type="text/javascript">
  <!--
$(generate_javascript)
  -->
  </script>
</body>

</html>
EOM

IFS="$OLD_IFS"

