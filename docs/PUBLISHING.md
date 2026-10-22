# دليل النشر على GitHub

المستودع: https://github.com/Scrim-Fix/Saudi-Fix

## أول مرة (مرة وحدة بس)

```powershell
gh auth login                      # اختر GitHub.com > HTTPS > Login with a web browser
git config --global user.name  "Rashid Alghamdi"
git config --global user.email "<ايميلك المسجل في GitHub>"
```

## نشر إصدار جديد

1. عدّل `Saudi_Fix.bat`، وغيّر الرقم في السطر `set "SF_VER=2.0"` (مثلاً إلى `2.1`)
2. حدّث `ReadMe.txt` و `CHANGELOG.md`
3. انسخ `docs/RELEASE_NOTES_v2.0.md` باسم الإصدار الجديد (مثل `RELEASE_NOTES_v2.1.md`) وعدّل الكلام اللي فيه
4. حدّث رابط زر Download ورقم الإصدار في `README.md`
5. جرّب الأداة في VirtualBox ([VM_Testing_Guide.md](VM_Testing_Guide.md))
6. شغّل:

```powershell
powershell -ExecutionPolicy Bypass -File tools\publish_release.ps1
```

السكربت يسوي التالي:
1. يفحص الأداة ويبني `dist/Saudi-Fix_vX.zip` و `dist/SHA256.txt`
2. يسوي Commit ويرفع التغييرات على GitHub
3. ينشئ الـ Release ويرفق فيه الـ ZIP و `SHA256.txt`

## روابط ثابتة تقدر تنشرها

| الرابط | وين يوديك |
|---|---|
| `https://github.com/Scrim-Fix/Saudi-Fix` | صفحة الأداة |
| `https://github.com/Scrim-Fix/Saudi-Fix/releases/latest` | صفحة آخر إصدار (يتحدث تلقائياً) |
| `https://github.com/Scrim-Fix/Saudi-Fix/releases/download/v2.0/Saudi-Fix_v2.0.zip` | تحميل مباشر للإصدار 2.0 |

> انشر رابط `releases/latest` في مقاطعك ومنشوراتك، لأنه يوصل الناس لآخر إصدار دايماً.

## إعدادات مقترحة في صفحة المستودع

- **About** (الترس جنب About): اكتب الوصف، وحط Website على رابط `releases/latest`، وأضف Topics: `windows` `gaming` `fps` `optimization` `batch` `windows-11`
- **Settings > General > Features**: طفِّ **Wiki** و **Projects** إذا ما تحتاجها، وخلّ **Issues** شغالة عشان الناس يبلغون عن المشاكل
- **Settings > Branches**: أضف حماية لفرع `main` عشان ما ينحذف بالغلط
