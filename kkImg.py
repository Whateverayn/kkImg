import flet as ft
import os
import subprocess
from subprocess import run, PIPE
import re
from datetime import datetime, timezone, timedelta
from zoneinfo import ZoneInfo
import tempfile

def convert_vlcsnap_filename_to_datetime(filename):
  match = re.match(r"vlcsnap-(\d{4})-(\d{2})-(\d{2})-(\d{2})h(\d{2})m(\d{2})s(\d{3}).png", filename)
  if match:
    return str(match.group(1)) + ":" + str(match.group(2)) + ":" + str(match.group(3)) + " " + str(match.group(4)) + ":" + str(match.group(5)) + ":" + str(match.group(6))
  else:
    return filename

def convert_virtualbox_filename_to_datetime(filename):
  match = re.match(r"VirtualBox_Windows_(\d{2})_(\d{2})_(\d{4})_(\d{2})_(\d{2})_(\d{2}).png", filename)
  if match:
    return str(match.group(3)) + ":" + str(match.group(2)) + ":" + str(match.group(1)) + " " + str(match.group(4)) + ":" + str(match.group(5)) + ":" + str(match.group(6))
  else:
    return filename

def convert_screenshot_filename_to_datetime(filename):
  match = re.match(r"Screenshot_(\d{4})(\d{2})(\d{2})-(\d{2})(\d{2})(\d{2}).png", filename)
  if match:
    return str(match.group(1)) + ":" + str(match.group(2)) + ":" + str(match.group(3)) + " " + str(match.group(4)) + ":" + str(match.group(5)) + ":" + str(match.group(6))
  else:
    return filename

def convert_screenshot_unix_filename_to_datetime(filename):
    match = re.match(r"Screenshot_(\d{10}).png", filename)
    if match:
        timestamp = int(match.group(1))
        datetime = datetime.fromtimestamp(timestamp, tz=timezone.utc)
        return datetime.strftime("%Y:%m:%d %H:%M:%S")
    else:
        return filename

# IMG_20220812_121806.jpg
def convert_img_filename_to_datetime(filename):
  match = re.match(r"IMG_(\d{4})(\d{2})(\d{2})_(\d{2})(\d{2})(\d{2}).jpg", filename)
  if match:
    return str(match.group(1)) + ":" + str(match.group(2)) + ":" + str(match.group(3)) + " " + str(match.group(4)) + ":" + str(match.group(5)) + ":" + str(match.group(6))
  else:
    return filename

# Polish_20220813_200837408.jpg
def convert_polish_filename_to_datetime(filename):
  match = re.match(r"Polish_(\d{4})(\d{2})(\d{2})_(\d{2})(\d{2})(\d{2})(\d{3}).jpg", filename)
  if match:
    return str(match.group(1)) + ":" + str(match.group(2)) + ":" + str(match.group(3)) + " " + str(match.group(4)) + ":" + str(match.group(5)) + ":" + str(match.group(6))
  else:
    return filename

# Unix時間と拡張子のみで構成されたファイル名かどうか
def _is_unix_timestamp_filename(filename):
  # ファイル名の末尾に拡張子が存在するかどうか
  if not filename.endswith(".jpg") and not filename.endswith(".png") and not filename.endswith(".mp4"):
    return False
  # ファイル名の先頭10文字が数字かどうか
  try:
    base_name = filename[:-4]
    # Unix時間が10桁または13桁であるかを確認
    if len(base_name) in [10, 13]:
      int(base_name)
    else:
      return False
  except ValueError:
    return False
  return True

# Unix時間と拡張子のみで構成されたファイル名の抽出
def convert_unix_timestamp_filename_to_datetime(filename):
  base_name = filename[:-4]
  # Unix時間をdatetimeに変換
  unix_timestamp = int(base_name)
  # 13桁のUnix時間の場合は10桁に変換
  if len(str(unix_timestamp)) == 13:
    unix_timestamp //= 1000
  datetimeA = datetime.fromtimestamp(unix_timestamp)
  # 日付と時刻を結合
  return datetimeA.strftime("%Y:%m:%d %H:%M:%S")

def convert_other_filename_to_datetime(filename):
  # ファイル名末尾の括弧と連番を削除
  filename = re.sub(r"\(.*\)", "", filename)
  # ハイフンをコロンに置き換える
  filename = filename.replace("-", ":")
  # 拡張子 ".png" を削除する
  if filename.endswith(".png"):
    filename = filename[:-4]
  return filename

def convert_filename_to_datetime(filename):
  """
  Args:
    filename: ファイル名
  Returns:
    yyyy:MM:dd hh:mm:ss
  """
  # VLCスナップショット
  if filename.startswith("vlcsnap-"):
    return convert_vlcsnap_filename_to_datetime(filename)
  # VirtualBox
  elif filename.startswith("VirtualBox_Windows_"):
    return convert_virtualbox_filename_to_datetime(filename)
  # スクリーンショット
  elif filename.startswith("Screenshot_"):
    # 2種類の抽出関数を試して、成功した方を返す
    datetime = convert_screenshot_filename_to_datetime(filename)
    if datetime != filename:
        return datetime
    return convert_screenshot_unix_filename_to_datetime(filename)

  # IMGファイル (IMG_20220812_121806.jpg)
  elif filename.startswith("IMG_"):
    return convert_img_filename_to_datetime(filename)

  # Polishファイル (Polish_20220813_200837408.jpg)
  elif filename.startswith("Polish_"):
    return convert_polish_filename_to_datetime(filename)

  # Unix時間と拡張子のみで構成されたファイル名 (1660318616181.mp4)
  elif _is_unix_timestamp_filename(filename):
    return convert_unix_timestamp_filename_to_datetime(filename)

  # その他
  else:
    return convert_other_filename_to_datetime(filename)

# 試験運用

def convert_filename_to_datetime_2(filename):
    patterns = [
        (r"vlcsnap-(\d{4})-(\d{2})-(\d{2})-(\d{2})h(\d{2})m(\d{2})s(\d{3}).png", "{0}:{1}:{2} {3}:{4}:{5}"),
        (r"VirtualBox_Windows_(\d{2})_(\d{2})_(\d{4})_(\d{2})_(\d{2})_(\d{2}).png", "{2}:{1}:{0} {3}:{4}:{5}"),
        (r"Screenshot_(\d{4})(\d{2})(\d{2})-(\d{2})(\d{2})(\d{2}).png", "{0}:{1}:{2} {3}:{4}:{5}"),
        (r"Screenshot_(\d{10}).png", lambda match: datetime.fromtimestamp(int(match.group(1)), tz=timezone.utc).strftime("%Y:%m:%d %H:%M:%S")),
        (r"IMG_(\d{4})(\d{2})(\d{2})_(\d{2})(\d{2})(\d{2}).jpg", "{0}:{1}:{2} {3}:{4}:{5}"),
        (r"Polish_(\d{8})_(\d{6})\d{3}.jpg", "{0}:{1}:{2} {3}:{4}:{5}"),
        (r"chrome_image_(\d{4})_(\d{2})_(\d{2}) (\d{2})_(\d{2})_(\d{2}) JST.png", "{0}:{1}:{2} {3}:{4}:{5}"),
        (r"(\d{13}).(jpg|png)", lambda match: datetime.fromtimestamp(int(match.group(1)) / 1000, tz=timezone(timedelta(hours=9))).strftime("%Y:%m:%d %H:%M:%S")),
    ]

    for pattern, format_str in patterns:
        match = re.match(pattern, filename)
        if match:
            if callable(format_str):
                return format_str(match)
            return format_str.format(*match.groups())
    return filename

# 廃止予定
def list_png_files(directory):
    png_files = [file for file in os.listdir(directory) if file.lower().endswith(('.png', '.jpeg', '.jpg', '.heic'))]
    return png_files

def list_files(directory, extensions):
    return [f for f in os.listdir(directory) if f.lower().endswith(extensions)] 

def get_image_files(exe, directory_path):
    exew = '.' + str(exe)
    png_files = [file for file in os.listdir(directory_path) if file.lower().endswith(exew)]
    return png_files

def replace_extension(filename, new_extension):
    base_name, _ = os.path.splitext(filename)  # 拡張子を除いたファイル名を取得
    new_filename = f"{base_name}.{new_extension}"  # 新しい拡張子を含むファイル名を作成
    return new_filename

def main(page: ft.Page):
    appHeight = 48
    appIconSize = 18
    page.window_title_bar_hidden = True
    page.window_title_bar_buttons_hidden = True
    page.window_always_on_top = True
    page.window_height = 480
    page.window_width = 720
    page.title = "kkImg"
    page.fonts = {
        "Malgun Gothic": "/fonts/malgunsl.ttf"
    }
    page.theme = ft.Theme(font_family="Malgun Gothic", color_scheme_seed='#26A79A')
    page.padding = ft.padding.only(top=appHeight,right=10,bottom=10,left=10)
    page.scroll = "AUTO"

    def max_click(e):
        page.window_maximized = True
        page.window_minimized = False
        page.update()

    def def_click(e):
        page.window_maximized = False
        page.window_minimized = False
        page.window_center()
        page.update()

    def min_click(e):
        page.window_maximized = False
        page.window_minimized = True
        page.update()

    def on_window_event(e):
        if page.window_maximized == True:
            nav_bt_unmaximize.visible = True
            nav_bt_maximize.visible = False
        else:
            nav_bt_unmaximize.visible = False
            nav_bt_maximize.visible = True
        page.update()


    page.on_window_event = on_window_event

    def dropdown_changed(e):
        if nav_func_switch.value == "PNG2AVIF":
            exBut.visible = True
            dtBut.visible = False
        elif nav_func_switch.value == "ExifWriter":
            exBut.visible = False
            dtBut.visible = True
        else:
            exBut.visible = False
            dtBut.visible = False
        page.update()

    nav_bt_unmaximize = ft.IconButton(ft.icons.KEYBOARD_ARROW_DOWN, on_click=def_click,height=appHeight,width=appHeight,tooltip="前のウインドウサイズに戻す",icon_size=appIconSize,visible=False)
    nav_bt_maximize = ft.IconButton(ft.icons.KEYBOARD_ARROW_UP, on_click=max_click,height=appHeight,width=appHeight,tooltip="ウインドウを最大化する",icon_size=appIconSize)
    nav_func_switch = ft.Dropdown(
            width=appHeight * 3,
            height=appHeight,
            border="NONE",
            on_change=dropdown_changed,
            content_padding=0,
            value="PNG2AVIF",
            border_radius=ft.border_radius.all(appHeight / 2),
            alignment=ft.alignment.center,
            options=[
                ft.dropdown.Option("PNG2AVIF"),
                ft.dropdown.Option("ExifWriter"),
            ],
        )
    appBar = ft.Container(
            ft.Row(
                [
                    ft.IconButton(ft.icons.CLOSE, on_click=lambda _: page.window_close(),height=appHeight,width=appHeight,tooltip="ウインドウを閉じる",icon_size=appIconSize),
                    ft.IconButton(ft.icons.MINIMIZE, on_click=min_click,height=appHeight,width=appHeight,tooltip="ウインドウをしまう",icon_size=appIconSize),
                    nav_bt_unmaximize,
                    nav_bt_maximize,
                    ft.WindowDragArea(
                        ft.Container(
                            ft.Text("kkImg"),alignment=ft.alignment.center
                        ), expand=True
                    ),
                    nav_func_switch
                ],
            vertical_alignment="STRETCH",height=appHeight,spacing=0),bgcolor=ft.colors.with_opacity(0.9, ft.colors.BACKGROUND)
    )

    def on_dialog_result(e: ft.FilePickerResultEvent):
        run_job_button.disabled = True
        run_job_button.text = "先に\"確認\"を実行してください"
        input_file_button.text = e.path
        job_ck_button.text = "変換ファイルを確認"
        page.update()
    def out_on_dialog_result(e: ft.FilePickerResultEvent):
        run_job_button.disabled = True
        run_job_button.text = "確認を実行してください"
        output_file_button.text = e.path
        page.update()

    def job_file_ck(e):
        job_ck_button.text = "お待ちください..."
        page.update()
        job_i_dir = input_file_button.text
        job_o_dir = output_file_button.text
        job_i_dir_list = list_png_files(job_i_dir)
        if len(job_i_dir_list) > 0:
            job_ck_button.text = str(len(job_i_dir_list)) + "件のファイルが見つかりました"
            run_job_button.disabled = False
            run_job_button.text = "実行"
        else:
            job_ck_button.text = "ファイルが見つかりません"
            run_job_button.disabled = True
            run_job_button.text = "確認を実行してください"
        page.update()

    def run_convert(e):
        png_file_dir = input_file_button.text
        avif_file_dir = output_file_button.text
        png_file_list = list_files(png_file_dir, ('.png', '.jpeg', '.jpg', '.heic'))
        conv_prog_ring.visible = True
        conv_prog_ring_p.visible = True
        num_count = 1
        for png_file in png_file_list:
            avif_file_name = replace_extension(png_file, 'avif')
            png_full_path = os.path.join(png_file_dir, png_file)
            avif_full_path = os.path.join(avif_file_dir, avif_file_name)
            run_job_button.text = f"[{num_count}] {avif_file_name}"
            conv_img_prev.src = png_full_path
            conv_prog_ring_p.value = num_count / len(png_file_list)
            page.update()
            num_count += 1

            # ファイル拡張子の確認
            file_extension = os.path.splitext(png_file)[1].lower()
            if file_extension in ['.png', '.jpeg', '.jpg']:
                # avifenc を使用して変換
                subprocess.run([
                    'avifenc', png_full_path, avif_full_path,
                    '--min', '0', '--max', '63', '-a', 'end-usage=q',
                    '-a', f'cq-level={int(quality_slider.value)}', '-a', 'tune=ssim',
                    '--jobs', f'{int(jobs_slider.value)}'
                ], check=True)
            else:
                # 一時ファイルを使用して ImageMagick から PNG に変換
                with tempfile.NamedTemporaryFile(suffix='.png', delete=False) as temp_png:
                    temp_png_name = temp_png.name
                    temp_png.close()
                    subprocess.run([
                        'magick', png_full_path, temp_png_name
                    ], check=True)
                    # PNG から AVIF に変換
                    subprocess.run([
                        'avifenc', '-a', 'end-usage=q',
                        '--min', '0', '--max', '63', 
                        '-a', f'cq-level={int(quality_slider.value)}',
                        '-a', 'tune=ssim',
                        temp_png_name, avif_full_path,
                        '--jobs', f'{int(jobs_slider.value)}'
                    ], check=True)

                    os.remove(temp_png_name)

            # Exif情報をコピー
            subprocess.run([
                "exiftool", 
                "-TagsFromFile", png_full_path, avif_full_path,
                "-overwrite_original"
            ], check=True)

        run_job_button.text = "完了"
        conv_img_prev.src="s\\t.png"
        conv_prog_ring.visible = False
        conv_prog_ring_p.visible = False
        run_job_button.disabled = False
        page.update()

    file_picker = ft.FilePicker(on_result=on_dialog_result)
    out_file_picker = ft.FilePicker(on_result=out_on_dialog_result)
    page.overlay.append(file_picker)
    page.overlay.append(out_file_picker)
    page.update()

    input_file_button = ft.ElevatedButton(text="読み込み元ディレクトリを選択...",on_click=lambda _: file_picker.get_directory_path())
    output_file_button = ft.ElevatedButton(text="書き出し先ディレクトリを選択...",on_click=lambda _: out_file_picker.get_directory_path())
    quality_slider = ft.Slider(min=0, max=63, divisions=63, label="高 - {value} - 低", value=30)
    jobs_slider = ft.Slider(min=1, max=os.cpu_count(), divisions=os.cpu_count(), label="遅 - {value} - 速", value=os.cpu_count()-1)
    job_ck_button = ft.ElevatedButton(text="変換ファイルを確認",on_click=job_file_ck)
    run_job_button = ft.FilledButton(text="確認を実行してください",on_click=run_convert,disabled=True)
    conv_img_prev = ft.Image(
                        src="s\\t.png",
                        fit=ft.ImageFit.CONTAIN,
                        repeat=ft.ImageRepeat.NO_REPEAT,
                        expand=True,
                        height=0,
                    )
    conv_prog_ring = ft.ProgressRing(color=ft.colors.TERTIARY,visible=False)
    conv_prog_ring_p = ft.ProgressRing(value=0,visible=False)
    conv_prev_stack = ft.Stack(
        [
            ft.Container(
                content=conv_img_prev,
                alignment=ft.alignment.center,
            ),
            ft.Container(
                content=conv_prog_ring,
                alignment=ft.alignment.center,
            ),
            ft.Container(
                content=conv_prog_ring_p,
                alignment=ft.alignment.center,
            )
        ],
        width=300,
        height=0,
        expand=True,
    )
    exBut = ft.Column(
        [
            ft.Row([ft.Text("入力",width=48),ft.Container(input_file_button,expand=True,tooltip="変換する画像があるディレクトリを選択します")],vertical_alignment="CENTER",spacing=10),
            ft.Row([ft.Text("出力",width=48),ft.Container(output_file_button,expand=True,tooltip="画像を保存するディレクトリを選択します")],vertical_alignment="CENTER",spacing=10),
            ft.Row([ft.Text("品質",width=48),ft.Container(quality_slider,expand=True,tooltip="エンコードの品質を選択します")],vertical_alignment="CENTER",spacing=10),
            ft.Row([ft.Text("仕事",width=48),ft.Container(jobs_slider,expand=True,tooltip="エンコードをするスレッドの数を選択します")],vertical_alignment="CENTER",spacing=10),
            ft.Row([ft.Text("確認",width=48),ft.Container(job_ck_button,expand=True,tooltip="間違いがないか確認します")],vertical_alignment="CENTER",spacing=10),
            ft.Row([ft.Container(run_job_button,expand=True,tooltip="変換を実行します")],vertical_alignment="CENTER",spacing=10),
            ft.Row([ft.Container(conv_prev_stack,expand=True)],vertical_alignment="CENTER",spacing=10),
        ]
    )

    def ex_on_dialog_result(e: ft.FilePickerResultEvent):
        ex_input_file_button.text = e.path

        page.update()

    def ex_job_file_ck(e):
        ex_directory_path = ex_input_file_button.text
        ex_img_list = get_image_files(ex_file_type_button.value, ex_directory_path)
        if len(ex_img_list) > 0:
            ex_job_ck_button.text = str(len(ex_img_list)) + "ファイルが見つかりました (*." + str(ex_file_type_button.value) + ")"
            ex_file_view.visible = True
            lv_r_c.controls.clear()
            for i in ex_img_list:
                lv_r_c.controls.append(ft.Radio(value=i, label=i))
        else:
            ex_job_ck_button.text = "入力項目を確認してください"
            ex_file_view.visible = False
        page.update()

    ex_file_picker = ft.FilePicker(on_result=ex_on_dialog_result)
    page.overlay.append(ex_file_picker)
    ex_input_file_button = ft.ElevatedButton(text="対象ディレクトリを選択...",on_click=lambda _: ex_file_picker.get_directory_path())
    ex_file_type_button = ft.TextField(label="拡張子", prefix_text="*.",hint_text="jpeg")
    ex_job_ck_button = ft.ElevatedButton(text="変換ファイルを確認",on_click=ex_job_file_ck)
    lv_r_c = ft.Column([])
    def radiogroup_changed(e):
        prev_file_name = e.control.value
        prev_file_dir = ex_input_file_button.text
        preb_file_path = os.path.join(prev_file_dir, prev_file_name)
        picture_con.src = preb_file_path

        buf = run('exiftool -T -DateTimeOriginal \"' + preb_file_path + '\"', shell=True, stdout=PIPE)
        # buf: bytes型
        data = buf.stdout.decode("UTF-8").strip("\n")
        # data: str型
        pic_date_inpit.value = data
        page.update()
    def img_time_predict(e):
        pic_date_inpit.value = convert_filename_to_datetime_2(lv_r.value)
        page.update()
    def img_time_write(e):
        prev_file_name = lv_r.value
        prev_file_dir = ex_input_file_button.text
        preb_file_path = os.path.join(prev_file_dir, prev_file_name)
        subprocess.run('exiftool -alldates=\"' + pic_date_inpit.value + '\" \"' + preb_file_path + '\"', shell=True)

    lv_r = ft.RadioGroup(content=lv_r_c,on_change=radiogroup_changed)
    lv = ft.Column([lv_r],scroll=ft.ScrollMode.AUTO)
    pic_date_inpit = ft.TextField(label="Date/Time Original (yyyy:MM:dd hh:mm:ss)", prefix_text="",hint_text="yyyy:MM:dd hh:mm:ss",expand=True)
    picture_con = ft.Image(
                        src="fonts\\framed_picture_3d.png",
                        fit=ft.ImageFit.CONTAIN,
                        repeat=ft.ImageRepeat.NO_REPEAT,
                        border_radius=ft.border_radius.all(10),
                        expand=True
                    )
    ex_file_view = ft.Column(
        [
            ft.Row(
                [
                    pic_date_inpit,
                    ft.ElevatedButton(text="推測", on_click=img_time_predict),
                    ft.FilledTonalButton(text="書込", on_click=img_time_write)
                ]
            ),
            ft.Row(
                [
                    lv,
                    picture_con
                ]
            )
        ],visible=False
    )
    def opt_table_height():
        lv.height=page.window_height - appHeight - 100
        picture_con.height=page.window_height - appHeight - 100
        conv_img_prev.height = page.window_height - appHeight - 350
        conv_prev_stack.height = page.window_height - appHeight - 350
        conv_prog_ring.height = (page.window_height - appHeight - 350) / 2
        conv_prog_ring.width = (page.window_height - appHeight - 350) / 2
        conv_prog_ring_p.height = (page.window_height - appHeight - 350) / 2
        conv_prog_ring_p.width = (page.window_height - appHeight - 350) / 2

        page.update()
    def page_resize(e):
        opt_table_height()
    page.on_resize = page_resize


    dtBut = ft.Column(
        [
            ft.Row([ft.Text("入力",width=48),ft.Container(ex_input_file_button,expand=True,tooltip="処理対象のディレクトリを選択します")],vertical_alignment="CENTER",spacing=10),
            ft.Row([ft.Text("種類",width=48),ft.Container(ex_file_type_button,expand=True,tooltip="処理対象の拡張子を選択します")],vertical_alignment="CENTER",spacing=10),
            ft.Row([ft.Text("検出",width=48),ft.Container(ex_job_ck_button,expand=True,tooltip="対象ファイルを検出します")],vertical_alignment="CENTER",spacing=10),
            ft.Row([ft.Container(ex_file_view,expand=True)],vertical_alignment="CENTER"),
        ],visible = False
    )

    appMain = ft.Container(
            content=ft.Column(
                [
                    exBut,
                    dtBut
                ]
            )
        )
    page.overlay.append(appBar)

    page.add(
        ft.Column(
            [
                appMain
            ],spacing=0,
        )
    )

ft.app(target=main, assets_dir="assets")

