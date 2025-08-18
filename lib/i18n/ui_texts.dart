// lib/i18n/ui_texts.dart
import 'package:korean_writing_app_new/lang_state.dart';

/// 간단한 UI 번역 맵 + 지원 언어 이름
class UiText {
  /// 각 키별 {언어코드: 번역문구}
  static const Map<String, Map<String, String>> _m = {
    // ──────────────────────────────────────────────────────────────
    // 앱 공통
    // ──────────────────────────────────────────────────────────────
    'appTitle': {
      'ko': 'Korean Writing App',
      'en': 'Korean Writing App',
      'ja': '韓国語書き取りアプリ',
      'zh': '韩语书写应用',
      'vi': 'Ứng dụng luyện viết tiếng Hàn',
      'fr': 'Application d’écriture coréenne',
      'es': 'Aplicación de escritura coreana',
      'ru': 'Приложение для письма по-корейски',
      'mn': 'Солонгос бичиг сургалтын апп',
    },
    'ok': {
      'ko': '확인', 'en': 'OK', 'ja': 'OK', 'zh': '确定', 'vi': 'OK',
      'fr': 'OK', 'es': 'Aceptar', 'ru': 'ОК', 'mn': 'OK',
    },
    'cancel': {
      'ko': '취소', 'en': 'Cancel', 'ja': 'キャンセル', 'zh': '取消', 'vi': 'Hủy',
      'fr': 'Annuler', 'es': 'Cancelar', 'ru': 'Отмена', 'mn': 'Цуцлах',
    },
    'more': {
      'ko': '도구 더보기', 'en': 'More', 'ja': 'その他', 'zh': '更多', 'vi': 'Thêm',
      'fr': 'Plus', 'es': 'Más', 'ru': 'Ещё', 'mn': 'Дэлгэрэнгүй',
    },
    // 메뉴 키 이름 혼용 대비(둘 다 제공)
    'changeLang': {
      'ko': '언어 변경', 'en': 'Change language', 'ja': '言語を変更', 'zh': '更改语言',
      'vi': 'Đổi ngôn ngữ', 'fr': 'Changer de langue', 'es': 'Cambiar idioma',
      'ru': 'Сменить язык', 'mn': 'Хэл солих',
    },
    'changeLanguage': {
      'ko': '언어 변경', 'en': 'Change language', 'ja': '言語を変更', 'zh': '更改语言',
      'vi': 'Đổi ngôn ngữ', 'fr': 'Changer de langue', 'es': 'Cambiar idioma',
      'ru': 'Сменить язык', 'mn': 'Хэл солих',
    },

    // 공통 네비게이션
    'back': {
      'ko': '뒤로',
      'en': 'Back',
      'ja': '戻る',
      'zh': '返回',
      'vi': 'Quay lại',
      'fr': 'Retour',
      'es': 'Atrás',
      'ru': 'Назад',
      'mn': 'Буцах',
    },

    // ──────────────────────────────────────────────────────────────
    // 언어 선택 화면
    // ──────────────────────────────────────────────────────────────
    'selectLanguage': {
      'ko': '언어를 선택하세요',
      'en': 'Choose your language',
      'ja': '言語を選択してください',
      'zh': '请选择语言',
      'vi': 'Chọn ngôn ngữ',
      'fr': 'Choisissez votre langue',
      'es': 'Elige tu idioma',
      'ru': 'Выберите язык',
      'mn': 'Хэлээ сонгоно уу',
    },
    'selectLanguagePrompt': {
      'ko': '앱에서 사용할 언어를 고르세요.',
      'en': 'Select the language for the app.',
      'ja': 'アプリで使用する言語を選択してください。',
      'zh': '请选择应用使用的语言。',
      'vi': 'Chọn ngôn ngữ dùng cho ứng dụng.',
      'fr': 'Sélectionnez la langue de l’application.',
      'es': 'Selecciona el idioma de la aplicación.',
      'ru': 'Выберите язык приложения.',
      'mn': 'Апп-д ашиглах хэлийг сонгоно уу.',
    },
    'youCanChangeLanguageLater': {
      'ko': '설정에서 언제든지 언어를 변경할 수 있습니다.',
      'en': 'You can change the language at any time in Settings.',
      'ja': '言語は設定からいつでも変更できます。',
      'zh': '可在设置中随时更改语言。',
      'vi': 'Có thể đổi ngôn ngữ trong Cài đặt bất cứ lúc nào.',
      'fr': 'Vous pourrez changer la langue dans Réglages.',
      'es': 'Puedes cambiar el idioma en Configuración en cualquier momento.',
      'ru': 'Язык можно изменить в настройках в любое время.',
      'mn': 'Тохиргоонд хэлийг дур үедээ сольж болно.',
    },
    'start': {
      'ko': '시작', 'en': 'Start', 'ja': '開始', 'zh': '开始', 'vi': 'Bắt đầu',
      'fr': 'Commencer', 'es': 'Empezar', 'ru': 'Начать', 'mn': 'Эхлэх',
    },

    // ──────────────────────────────────────────────────────────────
    // 쓰기 연습 / 도구
    // ──────────────────────────────────────────────────────────────
    'practice': {
      'ko': '쓰기 연습', 'en': 'Writing Practice', 'ja': '書き取り練習', 'zh': '书写练习',
      'vi': 'Luyện viết', 'fr': 'Exercice d’écriture', 'es': 'Práctica de escritura',
      'ru': 'Тренировка письма', 'mn': 'Бичгийн дасгал',
    },
    'read': {
      'ko': '읽기', 'en': 'Read', 'ja': '読み上げ', 'zh': '朗读', 'vi': 'Đọc',
      'fr': 'Lire', 'es': 'Leer', 'ru': 'Озвучить', 'mn': 'Уншуулах',
    },
    'toggleGuide': {
      'ko': '가이드 보이기/숨기기', 'en': 'Toggle Guide', 'ja': 'ガイドの表示/非表示',
      'zh': '显示/隐藏指南', 'vi': 'Bật/Tắt hướng dẫn', 'fr': 'Afficher/Masquer le guide',
      'es': 'Mostrar/Ocultar guía', 'ru': 'Показать/скрыть подсказку',
      'mn': 'Зааврыг хар/нуух',
    },
    'toggleGrid': {
      'ko': '격자 보이기/숨기기', 'en': 'Toggle Grid', 'ja': 'グリッドの表示/非表示',
      'zh': '显示/隐藏网格', 'vi': 'Bật/Tắt lưới', 'fr': 'Afficher/Masquer la grille',
      'es': 'Mostrar/Ocultar cuadrícula', 'ru': 'Показать/скрыть сетку',
      'mn': 'Сараалжилтыг хар/нуух',
    },
    'grid': {
      'ko': '격자', 'en': 'Grid', 'ja': 'グリッド', 'zh': '网格', 'vi': 'Lưới',
      'fr': 'Grille', 'es': 'Cuadrícula', 'ru': 'Сетка', 'mn': 'Сараалжилт',
    },
    'guide': {
      'ko': '가이드', 'en': 'Guide', 'ja': 'ガイド', 'zh': '指南', 'vi': 'Hướng dẫn',
      'fr': 'Guide', 'es': 'Guía', 'ru': 'Подсказка', 'mn': 'Заавар',
    },
    'undo': {
      'ko': '되돌리기', 'en': 'Undo', 'ja': '元に戻す', 'zh': '撤销', 'vi': 'Hoàn tác',
      'fr': 'Annuler', 'es': 'Deshacer', 'ru': 'Отменить', 'mn': 'Буцаах',
    },
    'clear': {
      'ko': '지우기', 'en': 'Clear', 'ja': 'クリア', 'zh': '清除', 'vi': 'Xóa',
      'fr': 'Effacer', 'es': 'Borrar', 'ru': 'Очистить', 'mn': 'Арилгах',
    },
    'toolMenu': {
      'ko': '도구 더보기', 'en': 'More', 'ja': 'その他', 'zh': '更多', 'vi': 'Thêm',
      'fr': 'Plus', 'es': 'Más', 'ru': 'Ещё', 'mn': 'Дэлгэрэнгүй',
    },

    // 팝업/옵션
    'pickColor': {
      'ko': '획 색상 선택', 'en': 'Pick stroke color', 'ja': '線の色を選択',
      'zh': '选择笔画颜色', 'vi': 'Chọn màu nét', 'fr': 'Choisir la couleur du trait',
      'es': 'Elegir color del trazo', 'ru': 'Выбрать цвет штриха',
      'mn': 'Зураасны өнгө сонгох',
    },
    'pickWidth': {
      'ko': '획 두께 선택', 'en': 'Pick stroke width', 'ja': '線の太さを選択',
      'zh': '选择笔画粗细', 'vi': 'Chọn độ dày nét', 'fr': 'Choisir l’épaisseur du trait',
      'es': 'Elegir grosor del trazo', 'ru': 'Выбрать толщину штриха',
      'mn': 'Зураасны зузаан сонгох',
    },
    'color': {
      'ko': '색상', 'en': 'Color', 'ja': '色', 'zh': '颜色', 'vi': 'Màu',
      'fr': 'Couleur', 'es': 'Color', 'ru': 'Цвет', 'mn': 'Өнгө',
    },
    'thickness': {
      'ko': '두께', 'en': 'Thickness', 'ja': '太さ', 'zh': '粗细', 'vi': 'Độ dày',
      'fr': 'Épaisseur', 'es': 'Grosor', 'ru': 'Толщина', 'mn': 'Зузаан',
    },
    'thin': {
      'ko': '얇게', 'en': 'Thin', 'ja': '細く', 'zh': '细', 'vi': 'Mảnh',
      'fr': 'Fin', 'es': 'Fino', 'ru': 'Тонкий', 'mn': 'Нарийн',
    },
    'thick': {
      'ko': '두껍게', 'en': 'Thick', 'ja': '太く', 'zh': '粗', 'vi': 'Đậm',
      'fr': 'Épais', 'es': 'Grueso', 'ru': 'Толстый', 'mn': 'Зузаан',
    },
    'savePng': {
      'ko': '이미지 저장 (PNG)', 'en': 'Save image (PNG)', 'ja': '画像を保存（PNG）',
      'zh': '保存图像（PNG）', 'vi': 'Lưu ảnh (PNG)', 'fr': 'Enregistrer l’image (PNG)',
      'es': 'Guardar imagen (PNG)', 'ru': 'Сохранить изображение (PNG)',
      'mn': 'Зургийг хадгалах (PNG)',
    },

    // ──────────────────────────────────────────────────────────────
    // 안내 문구
    // ──────────────────────────────────────────────────────────────
    'tip': {
      'ko':
      '팁: 마우스/손가락으로 따라 그리세요. 상단의 격자/가이드 토글, 되돌리기/지우기, 메뉴(⋮)에서 색·두께·저장을 사용할 수 있어요.',
      'en':
      'Tip: Draw with mouse/finger. Use grid/guide toggles, undo/clear, and menu (⋮) for color/width/save.',
      'ja':
      'ヒント: マウスや指でなぞってください。上部のグリッド/ガイド切替、元に戻す/クリア、メニュー(⋮)で色・太さ・保存が使えます。',
      'zh':
      '提示：用鼠标/手指描写。可使用顶部的网格/指南开关、撤销/清除，以及菜单(⋮)中的颜色/粗细/保存。',
      'vi':
      'Mẹo: Vẽ bằng chuột/ngón tay. Dùng các nút bật/tắt lưới & hướng dẫn, hoàn tác/xóa, và menu (⋮) để chọn màu/độ dày/lưu.',
      'fr':
      'Astuce : Dessinez à la souris/au doigt. Utilisez les bascules grille/guide, annuler/effacer et le menu (⋮) pour couleur/épaisseur/enregistrement.',
      'es':
      'Consejo: Dibuja con el ratón o el dedo. Usa los botones de guía/cuadrícula, deshacer/borrar y el menú (⋮) para color/grosor/guardar.',
      'ru':
      'Подсказка: Рисуйте мышью или пальцем. Вверху — переключатели сетки/подсказки, отмена/очистка и меню (⋮) для цвета/толщины/сохранения.',
      'mn':
      'Зөвлөмж: Хулгана эсвэл хуруугаар зур. Дээд талын сараалжилт/зааврыг асаах-унтраах, буцаах/устгах, мөн цэс(⋮)-ээр өнгө·зузаан·хадгалахыг сонгоно уу.',
    },
    'compositeNote': {
      'ko':
      '병서 자모(합용병서)는 조합 글자라 정해진 획순이 없습니다. 가이드를 참고해 모양을 익히고 자유롭게 연습해 보세요.',
      'en':
      'Consonant clusters have no fixed stroke order. Use the guide and practice freely.',
      'ja':
      '連結子音には決まった筆順がありません。ガイドを参考に自由に練習してください。',
      'zh': '辅音连缀没有固定的笔顺。请参考指南并自由练习。',
      'vi':
      'Cụm phụ âm không có thứ tự nét cố định. Hãy xem hướng dẫn và luyện tập tự do.',
      'fr':
      'Les groupes de consonnes n’ont pas d’ordre de traits fixe. Utilisez le guide et entraînez-vous librement.',
      'es':
      'Los grupos de consonantes no tienen un orden fijo de trazos. Usa la guía y practica libremente.',
      'ru':
      'У сочетаний согласных нет фиксированного порядка штрихов. Пользуйтесь подсказкой и тренируйтесь свободно.',
      'mn':
      'Нийлмэл гийгүүлэгчдэд тогтсон бичих дараалал байхгүй. Зааврыг ашиглан чөлөөтэй дадлага хийнэ үү.',
    },

    // ✅ 새로 추가: 아래아 안내(다국어)
    'araeOnly': {
      'ko': '아래아(ㆍ)는 현대 한국어에서 쓰이지 않아, 설명만 제공합니다.',
      'en': 'Arae-a (ㆍ) is not used in Modern Korean; description only.',
      'ja': 'アレア（ㆍ）は現代韓国語では使われません（説明のみ）。',
      'zh': '“ㆍ”在现代韩语中已不使用，仅提供说明。',
      'vi': 'Arae-a (ㆍ) không dùng trong tiếng Hàn hiện đại; chỉ có mô tả.',
      'fr': 'Arae-a (ㆍ) n’est pas utilisé en coréen moderne ; description seule.',
      'es': 'Arae-a (ㆍ) no se usa en coreano moderno; solo descripción.',
      'ru': 'Арэ-а (ㆍ) в современном корейском не используется; только описание.',
      'mn': 'Араэ-а (ㆍ) нь орчин үеийн солонгост хэрэглэдэггүй, тайлбар л байна.',
    },

    // ──────────────────────────────────────────────────────────────
    // 저장 결과
    // ──────────────────────────────────────────────────────────────
    'saved': {
      'ko': '이미지 저장됨', 'en': 'Image saved', 'ja': '画像を保存しました',
      'zh': '图像已保存', 'vi': 'Đã lưu ảnh', 'fr': 'Image enregistrée',
      'es': 'Imagen guardada', 'ru': 'Изображение сохранено', 'mn': 'Зураг хадгалаглаа',
    },
    'failed': {
      'ko': '저장 실패', 'en': 'Save failed', 'ja': '保存に失敗しました',
      'zh': '保存失败', 'vi': 'Lưu thất bại', 'fr': 'Échec de l’enregistrement',
      'es': 'Error al guardar', 'ru': 'Ошибка сохранения', 'mn': 'Хадгалах амжилтгүй',
    },

    // ──────────────────────────────────────────────────────────────
    // 색상 커스터마이즈
    // ──────────────────────────────────────────────────────────────
    'customizeColors': {
      'ko': '색상 설정', 'en': 'Customize colors', 'ja': '色の設定', 'zh': '自定义颜色',
      'vi': 'Tùy chỉnh màu', 'fr': 'Personnaliser les couleurs', 'es': 'Personalizar colores',
      'ru': 'Настроить цвета', 'mn': 'Өнгө тохируулах',
    },
    'cardColor': {
      'ko': '카드 색', 'en': 'Card color', 'ja': 'カード色', 'zh': '卡片颜色',
      'vi': 'Màu thẻ', 'fr': 'Couleur des cartes', 'es': 'Color de tarjeta',
      'ru': 'Цвет карточки', 'mn': 'Картын өнгө',
    },
    'letterColor': {
      'ko': '글자 색', 'en': 'Letter color', 'ja': '文字色', 'zh': '文字颜色',
      'vi': 'Màu chữ', 'fr': 'Couleur du texte', 'es': 'Color de letra',
      'ru': 'Цвет символа', 'mn': 'Тэмдэгтийн өнгө',
    },
    'reset': {
      'ko': '초기화', 'en': 'Reset', 'ja': 'リセット', 'zh': '重置',
      'vi': 'Đặt lại', 'fr': 'Réinitialiser', 'es': 'Restablecer',
      'ru': 'Сброс', 'mn': 'Эхлэх байдал',
    },

    // ──────────────────────────────────────────────────────────────
    // 그룹 헤더(자음자 섹션 제목)
    // ──────────────────────────────────────────────────────────────
    'basicCons': {
      'ko': '기본 자음자', 'en': 'Basic Consonants', 'ja': '基本子音',
      'zh': '基本子音', 'vi': 'Phụ âm cơ bản', 'fr': 'Consonnes de base',
      'es': 'Consonantes básicas', 'ru': 'Базовые согласные', 'mn': 'Үндсэн гийгүүлэгч',
    },
    'extendedCons': {
      'ko': '가획 자음자', 'en': 'Extended Consonants', 'ja': '加画子音',
      'zh': '加画子音', 'vi': 'Phụ âm mở rộng', 'fr': 'Consonnes dérivées',
      'es': 'Consonantes derivadas', 'ru': 'Производные согласные', 'mn': 'Нэмэлт гийгүүлэгч',
    },
    'variantCons': {
      'ko': '이체 자음자', 'en': 'Variant Consonants', 'ja': '異体子音',
      'zh': '异体子音', 'vi': 'Phụ âm dị thể', 'fr': 'Consonnes variantes',
      'es': 'Consonantes variantes', 'ru': 'Вариантные согласные', 'mn': 'Хувилбар гийгүүлэгч',
    },
    'others': {
      'ko': '기타', 'en': 'Others', 'ja': 'その他', 'zh': '其它', 'vi': 'Khác',
      'fr': 'Autres', 'es': 'Otros', 'ru': 'Прочее', 'mn': 'Бусад',
    },

    // ── 같은 의미의 별칭 키(렌더러 혼용 대비) ──
    'basicConsonants': {
      'ko': '기본 자음자', 'en': 'Basic Consonants', 'ja': '基本子音',
      'zh': '基本子音', 'vi': 'Phụ âm cơ bản', 'fr': 'Consonnes de base',
      'es': 'Consonantes básicas', 'ru': 'Базовые согласные', 'mn': 'Үндсэн гийгүүлэгч',
    },
    'strokedConsonants': {
      'ko': '가획 자음자', 'en': 'Extended Consonants', 'ja': '加画子音',
      'zh': '加画子音', 'vi': 'Phụ âm mở rộng', 'fr': 'Consonnes dérivées',
      'es': 'Consonantes derivadas', 'ru': 'Производные согласные', 'mn': 'Нэмэлт гийгүүлэгч',
    },
    'variantConsonants': {
      'ko': '이체 자음자', 'en': 'Variant Consonants', 'ja': '異体子音',
      'zh': '异体子音', 'vi': 'Phụ âm dị thể', 'fr': 'Consonnes variantes',
      'es': 'Consonantes variantes', 'ru': 'Вариантные согласные', 'mn': 'Хувилбар гийгүүлэгч',
    },

    // ──────────────────────────────────────────────────────────────
    // 그룹 헤더(모음자 섹션 제목)
    // ──────────────────────────────────────────────────────────────
    'basicVowels': {
      'ko':'기본 모음자','en':'Basic Vowels','ja':'基本母音','zh':'基本元音','vi':'Nguyên âm cơ bản',
      'fr':'Voyelles de base','es':'Vocales básicas','ru':'Базовые гласные','mn':'Үндсэн эгшиг',
    },
    'firstDerivedVowels': {
      'ko':'초출자','en':'First derivatives','ja':'初出字','zh':'初出字','vi':'Dẫn xuất bậc 1',
      'fr':'Dérivées 1','es':'Derivadas 1','ru':'Производные 1','mn':'I шатны уламжлал',
    },
    'secondDerivedVowels': {
      'ko':'재출자','en':'Second derivatives','ja':'再出字','zh':'再出字','vi':'Dẫn xuất bậc 2',
      'fr':'Dérivées 2','es':'Derivadas 2','ru':'Производные 2','mn':'II шатны уламжлал',
    },
    'mixedCompoundVowels': {
      'ko':'이자합용자','en':'Mixed compound vowels','ja':'混合合用母音','zh':'混合复合元音',
      'vi':'Nguyên âm ghép hỗn hợp','fr':'Voyelles composées mixtes','es':'Vocales compuestas mixtas',
      'ru':'Смешанные составные гласные','mn':'Холимог нийлмэл эгшиг',
    },
    'iHarmonyVowels': {
      'ko':'ㅣ상합자','en':'ㅣ-combining vowels','ja':'｜相合字','zh':'ㅣ相合字','vi':'Nguyên âm kết hợp với ㅣ',
      'fr':'Voyelles combinées ㅣ','es':'Vocales combinadas con ㅣ','ru':'Гармония с ㅣ','mn':'ㅣ хослол',
    },

    // ──────────────────────────────────────────────────────────────
    // 허브/메뉴
    // ──────────────────────────────────────────────────────────────
    'curriculum': {
      'ko':'학습 선택','en':'Choose what to learn','ja':'学習メニュー','zh':'学习菜单',
      'vi':'Chọn nội dung học','fr':'Choisir quoi étudier','es':'Elige qué aprender',
      'ru':'Выберите раздел','mn':'Юуг сурах вэ',
    },
    'menuJamo': {
      'ko':'자모','en':'Jamo','ja':'字母','zh':'字母','vi':'Jamo',
      'fr':'Jamo','es':'Jamo','ru':'Чамо','mn':'Жамо',
    },
    'menuLetters': {
      'ko':'글자(음절)','en':'Syllable Blocks','ja':'文字（音節）','zh':'音节方块',
      'vi':'Khối âm tiết','fr':'Blocs syllabiques','es':'Bloques silábicos',
      'ru':'Слоговые блоки','mn':'Үеийн блок',
    },
    'menuWords': {
      'ko':'단어','en':'Words','ja':'単語','zh':'单词','vi':'Từ vựng',
      'fr':'Mots','es':'Palabras','ru':'Слова','mn':'Үгс',
    },
    'menuConsonants': {
      'ko':'자음자','en':'Consonants','ja':'子音','zh':'辅音','vi':'Phụ âm',
      'fr':'Consonnes','es':'Consonantes','ru':'Согласные','mn':'Гийгүүлэгч',
    },
    'menuVowels': {
      'ko':'모음자','en':'Vowels','ja':'母音','zh':'元音','vi':'Nguyên âm',
      'fr':'Voyelles','es':'Vocales','ru':'Гласные','mn':'Эгшиг',
    },
    'comingSoon': {
      'ko':'준비 중입니다','en':'Coming soon','ja':'準備中です','zh':'即将推出',
      'vi':'Sắp ra mắt','fr':'Bientôt disponible','es':'Próximamente',
      'ru':'Скоро будет','mn':'Тун удахгүй',
    },
    'qaChecklist': {
      'ko':'QA 체크리스트',
      'en':'QA Checklist',
      'ja':'QAチェックリスト',
      'zh':'QA清单',
      'vi':'Danh sách QA',
      'fr':'Checklist QA',
      'es':'Lista de QA',
      'ru':'Чек-лист QA',
      'mn':'QA шалгах',
    },

    // ──────────────────────────────────────────────────────────────
    // 자모 허브 소개 — 모든 언어 채움
    // ──────────────────────────────────────────────────────────────
    'jamoIntro': {
      'ko': '한글은 기존의 어떤 문자를 오랜 세월에 걸쳐 변모·발전시킨 것이 아니라 세종대왕이 독창적으로 만든 글자이다. 이러한 점은 세계 문자 발달사에서 많지 않은 일로 한글의 가장 큰 특징이다. 또한, 세종대왕은 〈훈민정음〉에서 자음자 17자와 모음자 11자를 새로 만들고 각 자모들을 어떤 원리로써 만들었는지를 밝히고 있다. 이러한 특성으로 인하여 매우 과학적인 글자로 세계에서 인정받고 있다.',
      'en': 'Hangul was not evolved from an older script over centuries; it was an original writing system created by King Sejong. This rarity in the history of world scripts is a defining feature of Hangul. In the Hunminjeongeum, King Sejong presented 17 consonants and 11 vowels and explained the principles by which they were devised. Thanks to these features, Hangul is widely recognized as a highly scientific script.',
      'zh': '韩文并非在漫长岁月中由旧文字演变而来，而是由世宗大王独创的书写体系。这一特征在世界文字史上实属罕见，是韩文字最显著的特点之一。世宗大王在《训民正音》中新制17个子音和11个母音，并阐明了它们的创制原理。凭借这些特点，韩文被广泛认可为一种极具科学性的文字。',
      'ja': 'ハングルは古い文字から長い時間をかけて発展したものではなく、世宗大王によって独創的に作られた文字体系です。これは世界の文字史において稀有な特徴であり、ハングルの大きな特色です。『訓民正音』では17の子音と11の母音が示され、その創製原理が説明されています。こうした点から、ハングルは非常に科学的な文字として広く評価されています。',
      'vi': 'Hangul không phải là hệ chữ phát triển dần từ một văn tự cũ mà là hệ chữ viết do vua Sejong sáng tạo. Sự độc đáo này hiếm thấy trong lịch sử chữ viết thế giới và là đặc điểm nổi bật của Hangul. Trong Hunminjeongeum, vua Sejong đã trình bày 17 phụ âm và 11 nguyên âm cùng nguyên lý sáng tạo của chúng. Nhờ đó, Hangul được công nhận rộng rãi là một hệ chữ rất khoa học.',
      'fr': 'Le hangeul n’est pas l’aboutissement d’une évolution d’un système plus ancien : c’est une écriture originale créée par le roi Sejong. Cette singularité, rare dans l’histoire des écritures, constitue l’un de ses traits majeurs. Dans le Hunminjeongeum, le roi Sejong a présenté 17 consonnes et 11 voyelles et en a expliqué les principes de création. Grâce à ces caractéristiques, le hangeul est largement reconnu comme une écriture hautement scientifique.',
      'es': 'El hangul no evolucionó de una escritura anterior a lo largo de los siglos; fue creado originalmente por el rey Sejong. Esta rareza en la historia de las escrituras del mundo es un rasgo definitorio del hangul. En el Hunminjeongeum, el rey Sejong presentó 17 consonantes y 11 vocales y explicó los principios de su creación. Gracias a ello, el hangul es ampliamente reconocido como un sistema de escritura muy científico.',
      'ru': 'Хангыль — это не результат многовековой эволюции прежних письменностей, а оригинальная система письма, созданная королём Седжоном. Такая уникальность редка в истории мировых письменностей и является отличительной чертой хангыля. В «Хунминчонъым» король Седжон представил 17 согласных и 11 гласных и объяснил принципы их создания. Благодаря этому хангыля считают высоко научной письменностью.',
      'mn': 'Хангыль нь эртний бичгээс аажмаар хөгжсөн зүйл биш, харин хаан Сэжон өөрийн биеэр зохиосон бичгийн тогтолцоо юм. Энэ онцлог нь дэлхийн бичиг үсгийн түүхэнд ховор бөгөөд хангылийн хамгийн чухал шинж юм. «Хүнминжонъым»-д хаан Сэжон 17 гийгүүлэгч, 11 эгшгийг шинээр зохиож, тэдгээрийн зохиомжийн зарчмыг тайлбарласан байдаг. Иймээс хангылийг өндөр шинжлэх ухаанч бичиг гэж өргөнөөр үнэлдэг.',
    },
  };

  // ──────────────────────────────────────────────────────────────
  // 언어 코드 정규화/별칭/폴백 지원 t()
  // ──────────────────────────────────────────────────────────────

  static String _normLang(String? code) {
    if (code == null || code.isEmpty) return '';
    return code.toLowerCase();
  }

  static List<String> _langCandidates(String useRaw) {
    final use = _normLang(useRaw);        // ex) "zh-cn"
    final base = use.split('-').first;    // ex) "zh"

    const aliases = <String, String>{
      'zh-cn': 'zh',
      'zh-hans': 'zh',
      'zh-hant': 'zh-tw',
      'zh-tw': 'zh',
      'ja-jp': 'ja',
      'vi-vn': 'vi',
      'es-es': 'es',
      'fr-fr': 'fr',
      'ru-ru': 'ru',
      'mn-mn': 'mn',
    };

    final cand = <String>[
      use,
      base,
      if (aliases[use] != null) aliases[use]!,
      if (aliases[base] != null) aliases[base]!,
    ];

    final seen = <String>{};
    return [for (final c in cand) if (c.isNotEmpty && seen.add(c)) c];
  }

  /// 현재 언어에 맞는 문구를 반환 (강화 폴백: use/base/alias → en → ko → 첫 값)
  static String t(String key) {
    final v = _m[key];
    if (v == null) return key;

    final lang = AppLang.value;
    final map = <String, String>{
      for (final e in v.entries) e.key.toLowerCase(): e.value
    };

    for (final k in _langCandidates(lang)) {
      if (map.containsKey(k)) return map[k]!;
    }
    return map['en'] ?? map['ko'] ?? (map.isNotEmpty ? map.values.first : key);
  }

  /// 언어 코드 → 표시명 (언어 선택 리스트용) — 요청하신 순서 고정
  static Map<String, String> get supportedLangs => const {
    'ko': '한국어 (Korean)',
    'en': 'English',
    'ja': '日本語 (Japanese)',
    'zh': '中文 (Chinese)',
    'vi': 'Tiếng Việt (Vietnamese)',
    'fr': 'Français (French)',
    'es': 'Español (Spanish)',
    'ru': 'Русский (Russian)',
    'mn': 'Монгол (Mongolian)',
  };
}
