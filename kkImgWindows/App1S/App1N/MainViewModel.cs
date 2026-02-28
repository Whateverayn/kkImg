using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input; 
using Microsoft.UI.Xaml;

namespace App1N
{
    public partial class MainViewModel : ObservableObject
    {
        public KkTitleBarViewModel TitleBar { get; } = new KkTitleBarViewModel();

        // 終了コマンド
        [RelayCommand]
        private static void Exit()
        {
            Application.Current.Exit();
        }

        [RelayCommand]
        private static void CloseWindow()
        {
            // App クラスが覚えている今のアクティブなものに Close 命令を送る
            App.ActiveWindow?.Close();
        }

    }
}
