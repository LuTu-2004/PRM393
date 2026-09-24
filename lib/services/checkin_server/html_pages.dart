/// Self-contained Vietnamese pages served to students' phones: inline CSS,
/// no external fonts or scripts (the hotspot may have no internet).
library;

import 'dart:convert';

const _escape = HtmlEscape();

String esc(String s) => _escape.convert(s);

/// Header lines shown at the top of every page, e.g. "SE1801 · PRN211".
class PageInfo {
  const PageInfo({required this.classLine, required this.sessionLine});

  final String classLine;
  final String sessionLine;
}

const _css = '''
*{box-sizing:border-box}
html,body{margin:0;min-height:100%}
body{font-family:system-ui,-apple-system,"Segoe UI",Roboto,Arial,sans-serif;
  font-size:17px;line-height:1.5;color:#1E2233;background:#FBFCFE;
  -webkit-text-size-adjust:100%;overflow-wrap:anywhere}
main{max-width:440px;margin:0 auto;padding:28px 20px 40px}
h1{font-size:26px;line-height:1.3;margin:0 0 4px;font-weight:700}
.meta{color:#656B82;margin:0}
label{display:block;font-weight:600;margin:28px 0 8px}
input{width:100%;font-size:22px;padding:14px 16px;border:2px solid #C9CFE0;
  border-radius:12px;background:#fff;color:#1E2233;letter-spacing:1px;
  text-transform:uppercase;font-variant-numeric:tabular-nums}
input:focus{outline:none;border-color:#4A3AA8;box-shadow:0 0 0 3px #E5E1FA}
button{width:100%;margin-top:16px;min-height:56px;font-size:19px;font-weight:700;
  color:#fff;background:#4A3AA8;border:0;border-radius:12px}
button:disabled{background:#A59CD6}
.left{margin-top:14px;color:#656B82;font-variant-numeric:tabular-nums}
.left.low{color:#D0342C;font-weight:600}
.full{min-height:100vh;display:flex;flex-direction:column;justify-content:center;
  text-align:center;padding:32px 24px}
.ok{background:#1F7A45;color:#fff}
.err{background:#FCECEB;color:#1E2233}
.icon{width:96px;height:96px;margin:0 auto 20px}
.big{font-size:26px;font-weight:700;line-height:1.3;margin:0 0 8px}
.sub{font-size:18px;margin:0 0 6px}
.hint{margin-top:22px;font-weight:600}
.err .hint{color:#D0342C}
''';

String _page(String title, String body, {String bodyClass = ''}) =>
    '''
<!doctype html>
<html lang="vi">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1,viewport-fit=cover">
<meta name="robots" content="noindex">
<title>${esc(title)}</title>
<style>$_css</style>
</head>
<body class="$bodyClass">
$body
</body>
</html>
''';

const _okIcon =
    '<svg class="icon" viewBox="0 0 96 96" aria-hidden="true">'
    '<circle cx="48" cy="48" r="44" fill="none" stroke="#fff" stroke-width="5"/>'
    '<path d="M27 50 L42 64 L70 33" fill="none" stroke="#fff" stroke-width="8" '
    'stroke-linecap="round" stroke-linejoin="round"/></svg>';

const _errIcon =
    '<svg class="icon" viewBox="0 0 96 96" aria-hidden="true">'
    '<circle cx="48" cy="48" r="44" fill="none" stroke="#D0342C" stroke-width="5"/>'
    '<path d="M33 33 L63 63 M63 33 L33 63" fill="none" stroke="#D0342C" '
    'stroke-width="8" stroke-linecap="round"/></svg>';

/// Roll-number form. [ticket] is single-use and valid for [secondsLeft].
String formPage(
  PageInfo info, {
  required String ticket,
  required int secondsLeft,
}) {
  return _page('Điểm danh', '''
<main>
  <h1>Điểm danh</h1>
  <p class="meta">${esc(info.classLine)}</p>
  <p class="meta">${esc(info.sessionLine)}</p>
  <form method="post" action="/checkin" autocomplete="off" id="f">
    <input type="hidden" name="ticket" value="${esc(ticket)}">
    <label for="roll">MSSV</label>
    <input id="roll" name="roll_number" required autofocus maxlength="12"
      inputmode="text" autocapitalize="characters" autocorrect="off"
      spellcheck="false" placeholder="SE18xxxx">
    <button type="submit" id="b">Điểm danh</button>
  </form>
  <p class="left" id="left">Còn $secondsLeft giây</p>
</main>
<script>
(function(){
  var left=$secondsLeft,el=document.getElementById('left'),
      b=document.getElementById('b'),f=document.getElementById('f'),
      r=document.getElementById('roll');
  r.addEventListener('input',function(){
    var p=r.selectionStart;r.value=r.value.toUpperCase().replace(/\\s+/g,'');
    try{r.setSelectionRange(p,p)}catch(e){}
  });
  f.addEventListener('submit',function(){b.disabled=true;b.textContent='Đang gửi…'});
  var t=setInterval(function(){
    left--;
    if(left<=0){clearInterval(t);b.disabled=true;
      el.textContent='Hết thời gian. Hãy quét lại mã trên màn chiếu.';
      el.className='left low';return}
    el.textContent='Còn '+left+' giây';
    if(left<=15)el.className='left low';
  },1000);
})();
</script>
''');
}

String successPage(
  PageInfo info, {
  required String fullName,
  required String rollNumber,
  required String time,
}) {
  return _page('Đã ghi nhận', '''
<div class="full">
  $_okIcon
  <p class="big">Đã ghi nhận – ${esc(fullName)}</p>
  <p class="sub">${esc(rollNumber)} · lúc ${esc(time)}</p>
  <p class="sub">${esc(info.classLine)} · ${esc(info.sessionLine)}</p>
  <p class="hint">Kiểm tra đúng họ tên của bạn. Nếu sai, báo ngay cho giảng viên.</p>
</div>
''', bodyClass: 'ok');
}

/// Full-screen error with a reason and what to do next.
String errorPage({required String reason, required String hint}) {
  return _page('Chưa điểm danh được', '''
<div class="full">
  $_errIcon
  <p class="big">${esc(reason)}</p>
  <p class="hint">${esc(hint)}</p>
</div>
''', bodyClass: 'err');
}

const rescanHint = 'Hãy quét lại mã trên màn chiếu.';

String expiredPage() => errorPage(reason: 'Mã QR đã hết hạn', hint: rescanHint);

String ticketInvalidPage() => errorPage(
  reason: 'Phiên điểm danh trên điện thoại đã hết hạn hoặc đã được dùng',
  hint: rescanHint,
);

String pausedPage() => errorPage(
  reason: 'Điểm danh đang tạm dừng',
  hint: 'Chờ giảng viên mở lại rồi quét mã trên màn chiếu.',
);

String landingPage() => errorPage(
  reason: 'Chưa có mã điểm danh',
  hint: 'Hãy dùng camera quét mã QR trên màn chiếu.',
);
