/* My JS Library .. JS365Lib3.js  2023-01-18 */
"strict";

const VERSION = "3.3.7"

/* ------------------------------- エスケープ-----------------------------------*/
// URL エスケープ
function escURL(str, param=false) {
  let str2 = "";
  if (param) {
    // GET パラメータの場合 (; , / ? : @ & = + $ # を含む。)
    str2 = encodeURIComponent(str);
  }
  else {
    // URL の場合 (空白や全角文字のみ)
    str2 = encodeURI(str);
  }
   return str2;
}

// HTML のエスケープ
function escHTML(str) {
  if(typeof str !== 'string') {
    return str;
  }
  return str.replace(/[&'`"<>]/g, function(match) {
    return {
      '&': '&amp;',
      "'": '&#x27;',
      '`': '&#x60;',
      '"': '&quot;',
      '<': '&lt;',
      '>': '&gt;',
    }[match]
  });
}

/* --------------------------------- 要素 ---------------------------------------*/
// id, type (index) で指定したエレメントを取得する。
function E(id, type="i", index=0) {
  var el = null;
  switch (type) {
    case "i":  // id
      el = document.getElementById(id);
      break;
    case "n":  // name
      el = document.getElementsByName(id)[index];
      break;
    case "c":  // class
      el = document.getElementsByClassName(id)[index];
      break;
    case "t":  // tag
      el = document.getElementsByTagName(id)[index];
      break;
    default:  // id
      el = document.getElementById(id);
      break;
  }
  return el;
}

// name 属性で指定した要素一覧を返す。
function elName(name) {
  return document.getElementsByName(name);
}

// タグ名で指定した要素一覧を返す。
function elTag(name, typename=null) {
  const elements = document.getElementsByTagName(name);
  if (typename == null)
    return elements;
  let a = new Array();
  for (let i = 0; i < elements.length; i++) {
    if (elements[i].type == typename)
      a.push(elements[i]);
  }
  return a;
}

// クラス名で指定した要素一覧を返す。
function elClass(name) {
  return document.getElementsByClassName(name);
}

// 要素の値を得る。
function getValue(id, escape=true) {
  if (typeof id == "string") {
    const el = document.getElementById(id);
    if (el.value == undefined) {
      if (escape)
        return el.innerText;
      else
        return el.innerHTML;
    }
    else {
      return el.value;
    }
  }
  else if (typeof id == "object") {
    if (id.value == undefined) {
      if (escape)
        return id.innerText;
      else
        return id.innerHTML;
    }
    else {
      return id.value;
    }
  }
  else {
    return undefined;
  }
}

// 要素の値を設定する。
function setValue(id, value, escape=true) {
  if (typeof id == "string") {
    const el = document.getElementById(id);
    if (el.value == undefined) {
      if (escape) {
        if (value == null) {
          el.innerText = "null";
        }
        else {
          el.innerText = value.toString().replaceAll('&', "&amp;").replaceAll('<', "&lt;").replaceAll('>', "&gt;");
        }
      }
      else {
        el.innerHTML = value;
      }
    }
    else {
      el.value = value;
    }
  }
  else if (typeof id == "object") {
    if (id.value == undefined) {
      if (escape) {
        id.innerText = value.toString().replaceAll('&', "&amp;").replaceAll('<', "&lt;").replaceAll('>', "&gt;");
      }
      else {
        id.innerHTML = value;
      }
    }
    else {
      id.value = value;
    }
  }
  else {
    // 何もしない。
  }
}

// HTML文字列をタグの前後に挿入する。(デフォルトは開始タグの直後)
function insertHTML(id, html, position=1) {
  let el = id;
  if (typeof id == "string") {
    el = E(id);
  }
  switch (position) {
    case 0:
      el.insertAdjacentHTML("beforebegin", html);  // 開始タグの直前
      break;
    case 1:
      el.insertAdjacentHTML("afterbegin", html);  // 開始タグの直後
      break;
    case 2:
      el.insertAdjacentHTML("beforeend", html);   // 終了タグの直前
      break;
    case 3:
      el.insertAdjacentHTML("afterend", html);   // 終了タグの直後
      break;
    default:
      break;
  }
}

// insertHTML で子要素として挿入した要素をクリアする。
function clearHTML(id) {
  let el = id;
  if (typeof id == "string") {
    el = E(id);
  }
  el.innerHTML = "";
}

// 子要素を作成する。
function addChild(parent, tag) {
  let p = parent;
  let c = tag;
  if (typeof parent == "string") {
    p = document.getElementById(parent);
  }
  if (typeof tag == "string") {
    c = document.createElement(tag);
  }
  return p.appendChild(c);
}

// 要素の属性を得る。
function getAttr(id, attr) {
  let el = id;
  if (typeof el == "string") {
    el = document.getElementById(id);
  }
  return el.getAttribute(attr);
}

// 要素の属性を設定する。
function setAttr(id, attr, value) {
  let el = id;
  if (typeof el == "string") {
    el = document.getElementById(id);
  }
  el.setAttribute(attr, value);
}

// 要素の属性を削除する。
function dropAttr(id, attr) {
  let el = id;
  if (typeof el == "string") {
    el = document.getElementById(id);
  }
  el.removeAttribute(attr);
}

// 文字列 (span) のスタイルを変更する。
function setTextStyle(span_id, color="blank", bold=false, italic=false, underline=false, strike=false, font_size="normal") {
  let el = span_id;
  if (typeof span_id == "string") {
    el = document.getElementById(span_id);
  }
  el.style.color = color;
  el.style.fontWeight = bold ? "bold" : "normal";
  el.style.fontStyle = italic ? "italic" : "normal";
  el.style.textDecoration = underline ? "underline" : "normal";
  if (underline == false)
    el.style.textDecoration = strike ? "line-throught" : "normal";
  el.fontSize = font_size;
}

// 領域 (div) のスタイルを変更する。
function setDivStyle(div_id, border_style="solid", border_width="thin", border_color="black", bg_color="white", rounded=false, shadow=false) {
  let el = div_id;
  if (typeof el == "string") {
    el = document.getElementById(div_id);
  }
  el.style.borderStyle = border_style;
  el.style.borderWidth = border_width;
  el.style.borderColor = border_color;
  el.style.backgroundColor = bg_color;
  el.style.borderRadius = rounded ? "7px" : "none";
  el.style.boxShadow = shadow ? "10px 5px 5px" : "none";
}

// 円や矩形の SVG を返す。
function bullet(shape="rect", width=32, height=32, border_width=1, border_color="black", bg_color="white") {
  let svg = "";
  if (shape == "rect") {  // 矩形の場合
    svg = `<svg
  width = "${width + 1}"
  height="${height + 1}"
  xmlns="http://www.w3.org/2000/svg"
  version="1.1"
 >
  <rect
     x="0" y="0"
    width="${width}" height="${height}"
    stroke_width="${border_width}"
    stroke="${border_color}"
    fill="${bg_color}" />
</svg>`;
  }
  else if (shape == "circle") { // 円の場合
   const x = Math.round(width / 2.0);
   const y = Math.round(height / 2.0);
   const r = Math.round(width / 2.0);
    svg = `<svg
      width="${width + 1}" height="${height + 1}"
      xmlns="http://www.w3.org/2000/svg"
      version="1.1"
 >
    <circle cx="${x}" cy="${y}" r="${r}"
     stroke_width="${border_width}"
     stroke="${border_color}"
     fill="${bg_color}" />
</svg>`;
  }
  else {
    // reserved.
  }
  return svg;
}

// チェックボックス / ラジオボタンのチェック状態を得る。id はチェックボックスの id または要素オブジェクト。
function getCheck(id) {
  let el = id;
  if (typeof id == "string") {
    el = document.getElementById(id);
  }
  return el.checked;
}

// ラジオボタンのチェックされている id を得る。
function getCheckedId(name) {
  let radios = name;
  if (typeof name == "string") {
    radios = document.getElementsByName(name);
  }
  let id = "";
  let i = 0;
  for (let c of radios) {
    if (c.checked) {
      id = c.id;
      break;
    }
    i++;
  }
  if (id == undefined)
    return id;
  else
    return id;
}

// チェックボックス / ラジオボタンのチェック状態をセットする。id はチェックボックスの id またはオブジェクト。
function setCheck(id, checked=true) {
  let el = id;
  if (typeof id == "string") {
    el = document.getElementById(id);
  }
  el.checked = checked;
}

// ラジオボタングループの指定した番号のラジオボタンをチェックする。
function setCheckByIndex(elements, index) {
  elements[index].checked = true;
}

// セレクタ― (ドロップダウン) の選択されているオプション(値)を得る。
function getSelectValue(id) {
  let el = id;
  if (typeof id == "string") {
    el = document.getElementById(id);
  }
  return el.value;
}

// セレクタ― (ドロップダウン) のオプションを選択状態を設定する。
function setSelect(id, index, check=true) {
  let el = id;
  if (typeof id == "string") {
    el = document.getElementById(id);
  }
  el.options[index].selected = check;
}

/* ----------------------------- Serialize ------------------ */

// 連想配列 (Object) を URL 形式に変換する。
function hash_to_params(hash) {
  let str = "";
  for (const [k, v] of Object.entries(hash)) {
    str += (k + "=" + escURL(v) + "&");
  }
  return str.substring(0, str.length - 1);
}

// id の配列を URL 形式に変換する。
function array_to_params(idlist) {
  let str = "";
  for (let id of idlist) {
    const v = getValue(id);
    str += (id + "=" + escURL(v) + "&");
  }
  return str.substring(0, str.length - 1);
}

/* ----------------------------- Fetch API ------------------------------- */

// 指定した完全なリクエストパス (URL) から GET メソッドで各種データを得る。data は連想配列 (object).
async function fetchGET(url, data=null) {
  let url2 = url;
  if (data != null) {
    url2 = url + "?" + hash_to_params(data);
  }
  const response = await fetch(url2);
  let y = "";
  const content_type = response.headers.get("Content-Type");
  if (content_type.startsWith("application/json"))
    y = await response.json();
  else if (content_type.startsWith("text/plain"))
    y = await response.text();
  else if (content_type.startsWith("text/html"))
    y = await response.text();
  else if (content_type.startsWith("application/xml"))
    y = await response.xml();
  else
    y = await response.blob();
  return y;
}

// 指定した URL から POST メソッドで各種データを得る。data は連想配列 (map).
async function fetchPOST(url, data) {
  const body = hash_to_params(data);
  const options = {"method":"POST", "headers":{"content-type":"x-www-form-urlencoded"}, "body":body};
  const response = await fetch(url, options);
  y = "";
  const content_type = response.headers.get("Content-Type");
  if (content_type.startsWith("application/json"))
    y = await response.json();
  else if (content_type.startsWith("text/plain"))
    y = await response.text();
  else if(content_type.startsWith("text/html"))
    y = await response.text();
  else if(content_type.startsWith("application/xml"))
    y = await response.xml();
  else
    y = await response.blob();
  return y;
}

// 指定した URL にフォームを POST し結果 (JSON) を得る。
async function fetchMultipartForm(url, form) {
  const formdata = new FormData(form);
  const options = {"method":"POST", "body":formdata};
  const response = await fetch(url, options);
  const data = await response.json();
  return data;
}

// 指定した URL にフォームを POST し結果 (JSON) を得る。(fetchMultipartForm()をコールしているだけ)
async function fetchFormData(url, form) {
  let form1 = form;
  if (typeof form == "string") {
     form1 = document.getElementById(form);
  }
  const data = await fetchMultipartForm(url, form1);
  return data;
}

// 指定した URL に JSON を GET / POST し結果 (JSON) を得る。
async function fetchJSON(url, json) {
  if (typeof json != "string")
    json = JSON.stringify(json);
  const options = {"method":"POST", "headers":{"content-type":"application/json"}, "body":json};
  const response = await fetch(url, options);
  const data = await response.json();
  return data;
}

// 指定した URL に BLOB を POST し結果 (JSON) を得る。
async function fetchBLOB(url, buffer) {
  const options = {"method":"POST", "headers":{"content-type":"application/octed-stream"}, "body":buffer};
  const response = await fetch(url, options);
  const data = await response.json();
  return data;
}

/* ---------------------------- Events --------------------------- */

// click イベントハンドラを追加する。
function clickEvent(id, callback) {
  let el = id;
  if (typeof id == "string") {
    el = document.getElementById(id);
  }
  if (el == null) {
    alert("The element is null. (You must use this after the page loaded)");
    return;
  }
  el.addEventListener("click", callback, {passive: false});
}

// change イベントハンドラを追加する。
function changeEvent(id, callback) {
  let el = id;
  if (typeof id == "string") {
    el = document.getElementById(id);
  }
  if (el == null) {
    alert("The element is null. (You must use this after the page loaded)");
    return;
  }
  el.addEventListener("change", callback, {passive: false});
}

// フォームが送信されるときのイベントハンドラを追加する。
function submitEvent(form, callback) {
  let el = form;
  if (typeof form == "string") {
    el = document.getElementById(form);
  }
  if (el == null) {
    alert("The form is null. (You must use this after the page loaded)");
    return;
  }
  el.addEventListener("submit", callback);
}

// ページがロードされたときのハンドラを追加する。
function onPageLoad(callback) {
  window.onload = callback;
}

// ドラッグ開始のイベントハンドラ
function onDragEnter(event) {
  event.preventDefault();
  event.dataTransfer.dropEffect = 'copy';
}

// ドラッグ中のイベントハンドラ
function onDragOver(event) {
  event.preventDefault();
  event.dataTransfer.dropEffect = 'copy';
}

// ファイルがドロップしたとき (control は input[type="file"] オブジェクトであること)
//  直接、イベントハンドラとして呼び出さず間接的に呼び出したほうが良い。
function onDrop(event, control, p) {
    // ドロップされたデータを取得する。
    var files = event.dataTransfer.files;
    // input[type="file"] の control.files を設定する。
    control.files = files;
    // <div id="dest"></div> p = "dest" にファイル名をを表示
    setValue(p, files[0].name);

    // 既定の動作をキャンセルする。(ファイル内容が表示されないようにする)
    event.preventDefault();
}

/* ----------------------------- Storage ----------------------------- */
// ストレージのキーの一覧を得る。prefix が空でないときはその文字列が先頭にあるキー (prefix を除いたもの) だけを取得する)
function getStorageKeys(prefix="", session=true) {
  let storage = sessionStorage;
  if (session == false)
    storage = localStorage;
  let result = [];
  for (let i = 0; i < storage.length; i++) {
    let key = storage.key(i);
    if (prefix != "" && key.startsWith(prefix)) {
      key = key.replace(prefix, "");
    }
    result.push(key);
  }
  return result;
}

// ストレージのキーに対する値を得る。(localStorage は他のアプリケーションと共有するため、prefix を付けないとキーが競合する)
function getStorageValue(key, prefix="", session=true) {
  let storage = sessionStorage;
  if (session == false)
    storage = localStorage;
  key = prefix + key;
  return storage.getItem(key);
}

// ストレージのキーに対する値を追加または置換する。(localStorage は他のアプリケーションと共有するため、prefix を付けないとキーが競合する)
function setStorageValue(key, value, prefix="", session=true) {
  let storage = sessionStorage;
  if (session == false)
    storage = localStorage;
  key = prefix + key;
  storage.setItem(key, value);
}

// sessionStorage ストレージをクリアする。(localStorage は他のアプリケーションと共有するため個別のキーを削除することによりクリアすること)
function clearSessionStorage() {
  sessionStorage.clear();
}

// ストレージのキーを削除する。(localStorage は他のアプリケーションと共有するため、prefix でアプリケーションを区別する)
function deleteStorageKey(key, prefix="", session=true) {
  let storage = sessionStorage;
  if (session == false)
    storage = localStorage;
  storage.removeItem(prefix + key);
}

/* ----------------------------- HTML 作成 ----------------------------- */

// HTML テーブルを作成する。
function htmlTable(rows, header=false, table="", tr="", th="", td="") {
  let html = "";
  let row = rows[0];
  let n = row.length;
  let tagtr = "<tr>";
  if (tr != "") {
    tagtr = `<tr class="${tr}">`;
  }
  tagtd = "<td>";
  if (td != "") {
    tagtd = `<td class="${td}">`;
  }
  if (table == "") {
    html += "<table>\n";
  }
  else {
    html += `<table class="${table}">\n`;
  }
  let i = 0;
  // ヘッダ行
  if (header) {
    i = 1;
    html += tagtr;
    if (th == "") {
      for (let h = 0; h < n; h++) {
        html += `<th>"${rows[0][h]}"</th>`;
      }
    }
    else {
        html += `<th class="${th}">"${rows[0][h]}"</th>`;
    }
    html += "</tr>\n";
  }
  // データ行
  for (; i < rows.length; i++) {
    html += tagtr;
    for (let j = 0; j < n; j++) {
      html += `${tagtd}${rows[i][j]}</td>`;
    }
    html += "</tr>\n";
  }
  html += "</table>\n";
  return html;
}

// HTML リストを作成する。
function htmlList(data, type="ul", ul="", li="") {
  html = `<${type}>\n`;
  if (ul != "")
    html = `<${type} class="${ul}">\n`;
  let tagli = "<li>";
  if (li != "")
    tagli = `<li class="${li}">`;
  const n = data.length;
  for (let i = 0; i < n; i++) {
     html += `${tagli}${data[i]}</li>\n`;
  }
  html += `</${type}>\n`;
  return html;
}

// HTML アンカー (aタグ) を作成する。
function htmlAnchor(url, text, newpage=false) {
  html = `<a href="${url}"`;
  if (newpage == false)
     html += ">";
  else
     html += " target=\"_blank\">";
  html += `${text}</a>`;
  return html;
}

/* ------------------------- Cookies ----------------------------------------------- */

// ローカルに保存されている全クッキーを辞書として返す。(Set-Cookie の属性によっては使用できない)
function getAllCookies() {
  const allCookie = document.cookie;
  if (allCookie == "")
    return {};
  const listCookie = allCookie.split("; ");
  let cookies = {};
  if (listCookie.length > 0) {
    for (const cookie of listCookie) {
       const kvpair = cookie.split("=");
       const key = kvpair[0].trim();
       const value = kvpair[1].trim();
       cookies[key] = value;
    }
  }
  return cookies;
}

// ローカルに保存されているクッキーに追加あるいは書き換える。(Set-Cookie の属性によっては使用できない)
function setCookie(key, value) {
  document.cookie = `${key}=${value}`;
}

// ローカルに保存されているクッキーを削除する。
function removeCookie(key) {
  document.cookie = `${key}=;max-age=0`;
}

/* -------------------------------------- 日付時刻 ------------------------------------ */
// yyyy-mm-dd hh:mm:ss 形式かつ JST の現在の時刻を文字列として返す。
function getNowString() {
  const now = new Date();
  return now.toLocaleString();
}

// yyyy-mm-dd hh:mm:ss 形式の文字列を JST として Date オブジェクトに変換する。
function parseJSTString(str) {
  return new Date(str);
}

// dd-mm-yyyy hh:mm:ss 形式の文字列を UTC として Date オブジェクトに変換する。
function parseUTCString(str) {
  return new Date(str + " GMT");
}

// Date オブジェクトを YYYY-mm-dd HH:MM;SS 形式の文字列として返す。
function getDateTimeString(dtime) {
  let s = dtime.getFullYear() + "-" + ('0' + (dtime.getMonth() + 1)).slice(-2) + "-" + ('0' + dtime.getDate()).slice(-2);
  s += " " + ('0' + dtime.getHours()).slice(-2) + ":" + ('0' + dtime.getMinutes()).slice(-2) + ":" + ('0' + dtime.getSeconds()).slice(-2);
  return s;
}

/*
   ドラッグ＆ドロップ フォームの例

  <script>
    function dropAction(event) {
       onDrop(event, form1.file1, "dest");
    }
  </script>

  <form name="form1" method="POST" enctype="multipart/form-data" action="/file_upload">
   <input type="file" name="file1" style="display:none">
   <div id="dest" class="section" draggable="true"
     ondragenter="onDragEnter(event);"
     ondragover="onDragOver(event);"
     ondrop="dropAction(event);">
    ここへドロップ (1個のみ)
   </div>
   <div style="margin-left:28%;margin-top:25px;"><button type="submit">Submit</button></div>
  </form>
*/
