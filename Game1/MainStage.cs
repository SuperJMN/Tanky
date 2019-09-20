using System;
using System.Reactive.Linq;
using System.Windows.Threading;
using Microsoft.Xna.Framework.Content;
using SuperJMN.MonoGame;
using SuperJMN.MonoGame.Common;
using TankyReloaded.Actors;

namespace TankyReloaded
{
    public class MainStage : Stage, IDisposable
    {
        private readonly IDisposable enemyAdder;

        public MainStage(ContentManager content, double width, double height) : base(content, width, height)
        {
            enemyAdder = Observable.Interval(TimeSpan.FromSeconds(2)).ObserveOn(Dispatcher.CurrentDispatcher).Subscribe(
                _ =>
                {
                    var ship = new Ship();
                    ship.AlignTo(new RectangleAdapter(this.GetBounds()), Alignment.ToLeftSide);
                    ship.Top -= 100;
                    Add(ship);
                });
        }

        public override void Dispose()
        {
            enemyAdder.Dispose();
            base.Dispose();
        }
    }
}