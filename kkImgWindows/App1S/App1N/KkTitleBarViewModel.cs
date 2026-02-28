using CommunityToolkit.Mvvm.ComponentModel;
using Windows.UI;
using Microsoft.UI;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Media;
using System;
using System.Collections.Generic;
using System.Media;
using System.Text;

namespace App1N
{
    public partial class KkTitleBarViewModel: ObservableObject
    {
        [ObservableProperty]
        public partial long UnixSeconds { get; set; }

        [ObservableProperty]
        public partial Brush UnixSecondsColor { get; set; }

        [ObservableProperty]
        public partial string BinaryTime { get; set; }

        [ObservableProperty]
        public partial string MachineName { get; set; }

        private readonly DispatcherTimer _timer;

        public KkTitleBarViewModel()
        {
            BinaryTime = "";
            UnixSecondsColor = new SolidColorBrush(Colors.Indigo);

            MachineName = $"{Environment.MachineName}\\{Environment.UserName}";

            _timer = new DispatcherTimer { Interval = TimeSpan.FromSeconds(1) };
            _timer.Tick += (s, e) => Update();
            _timer.Start();

            Update();
        }

        private void Update()
        {
            var now = DateTimeOffset.Now;
            UnixSeconds = now.ToUnixTimeSeconds();

            // 判定 IsPrime(UnixSeconds)
            if (IsPrime(UnixSeconds))
            {
                // OSのアクセントカラー
                if (Application.Current.Resources.TryGetValue("SystemAccentColor", out object accentColorObj) &&
                    accentColorObj is Color accentColor)
                {
                    UnixSecondsColor = new SolidColorBrush(accentColor);
                }
                else
                {
                    // フォールバック
                    UnixSecondsColor = new SolidColorBrush(Colors.DodgerBlue);
                }
                SystemSounds.Asterisk.Play(); 
            }
            else
            {
                UnixSecondsColor = new SolidColorBrush(Colors.Transparent);
            }

            BinaryTime = Convert.ToString(now.Second, 2).PadLeft(6, '0');
        }

        // 判定アルゴリズム
        private static bool IsPrime(long n)
        {
            if (n <= 1) return false;
            if (n <= 3) return true;
            if (n % 2 == 0 || n % 3 == 0) return false;
            for (long i = 5; i * i <= n; i += 6)
            {
                if (n % i == 0 || n % (i + 2) == 0) return false;
            }
            return true;
        }
    }
}
