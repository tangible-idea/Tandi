"""store/google_play/listing.json 을 만든다. 글자 수 제한(제목 30, 짧은 설명 80, 전체 4000)을 검사한다."""
import json
ko=open('store/app_store/metadata/ko/description.txt').read().strip()
ko=ko.replace("저장한 파일은 사진 앱의 'Townloader' 앨범에 모입니다.","저장한 파일은 갤러리의 'Townloader' 앨범에 모입니다.").replace('■ 사진 앱에 깔끔하게 정리','■ 갤러리에 깔끔하게 정리')
en="""One link. Original quality.

Townloader saves photos and videos from public posts in the highest quality available. Paste a link you copied, or pick Townloader from the share button in the app you're browsing.

■ Download straight from the share button
Tap Share → Townloader in the app you're using and the download starts right away. No copying and pasting links.

■ Original quality
Photos are saved at the largest resolution and videos at the highest quality. If you just want a quick look, choose "Smallest size" in Settings.

■ Multi-photo posts in one go
Posts with several photos and videos are downloaded all at once.

■ Browse a whole account
See a public account's posts, reels and stories as a list, and save only the ones you want.

■ Neatly organized in your gallery
Saved files go to the "Townloader" album in your gallery, with the account name in the file name so they're easy to find later.

■ Download list
Track the progress of multiple files at a glance, and cancel or retry when needed.

Supported links
• Posts, reels and multi-photo posts
• Stories and highlights
• Public Threads posts

Please note
• Only content from public accounts can be saved. Private accounts are not supported.
• Copyright of saved content belongs to its original creator. Use it for personal archiving only, and get the rights holder's permission before redistributing it or using it commercially.
• Townloader is not affiliated with or endorsed by Instagram, Threads or Meta."""
g=lambda l:{"icon":"store/google_play/icon_512.png","feature_graphic":f"store/google_play/{l}/feature_graphic.png","phone_screenshots":[f"store/google_play/{l}/0{i}" for i in ("1_link.png","2_share.png","3_profile.png")]}
d={
 "app":{"name":"Townloader","package":"net.tangibleidea.townloader","play_app_id":"4975870942852943050","developer_id":"7866548385374519877"},
 "contact":{"email":"fantasysa@gmail.com","website":"https://github.com/tangible-idea/Townloader","privacy_policy_url":"https://github.com/tangible-idea/Townloader/blob/main/PRIVACY.md"},
 "category":{"type":"App","category":"Tools"},
 "listings":{
  "ko-KR":{"default":True,"title":"Townloader - 사진·동영상 원본 저장","short_description":"공유 버튼 한 번으로 공개 게시물의 사진과 동영상을 원본 화질 그대로 저장하세요.","full_description":ko,"graphics":g("ko-KR")},
  "en-US":{"title":"Townloader - Photo Video Saver","short_description":"Save photos and videos from public posts in original quality with one tap.","full_description":en,"graphics":g("en-US")}}
}
for l,v in d["listings"].items():
    assert len(v["title"])<=30,(l,len(v["title"])); assert len(v["short_description"])<=80; assert len(v["full_description"])<=4000
json.dump(d,open('store/google_play/listing.json','w'),ensure_ascii=False,indent=2)
print({l:(len(v["title"]),len(v["short_description"]),len(v["full_description"])) for l,v in d["listings"].items()})
