using System;
using System.Reactive.Linq;
using System.Windows.Threading;
using Microsoft.Xna.Framework.Content;
using SuperJMN.MonoGame;
using TankyReloaded.Actors;

namespace TankyReloaded
{
    public class MainStage : Stage, IDisposable
    {
        private readonly IDisposable enemyAdder;

        public MainStage(ContentManager content, double width, double height) : base(content, width, height)
        {
            enemyAdder = Observable.Interval(TimeSpan.FromSeconds(2)).ObserveOn(Dispatcher.CurrentDispatcher).Subscribe(
                _ => Add(new Ship
                {
                    Top = Utils.Random.Next((int) Constants.GroundTop),
                    Left = width
                }));
        }

        public override void Dispose()
        {
            enemyAdder.Dispose();
            base.Dispose();
        }
    }
}