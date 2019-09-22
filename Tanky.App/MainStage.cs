using System;
using System.Collections.Generic;
using System.Reactive.Linq;
using System.Reactive.Subjects;
using System.Windows.Threading;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Content;
using Microsoft.Xna.Framework.Graphics;
using SuperJMN.MonoGame;
using SuperJMN.MonoGame.Common;
using TankyApp.Actors;

namespace TankyApp
{
    public class MainStage : Stage, IDisposable
    {
        private readonly Texture2D background;

        private readonly IDictionary<IDestructable, IDisposable> destroyables =
            new Dictionary<IDestructable, IDisposable>();

        private readonly ISubject<DefeatedEvent> destroyed = new Subject<DefeatedEvent>();
        private readonly IDisposable enemyAdder;

        private readonly IDictionary<Type, int> scoreTable = new Dictionary<Type, int>
        {
            {typeof(Ship), 100},
            {typeof(Bomb), 20}
        };

        public MainStage(ContentManager content, double width, double height) : base(content, width, height)
        {
            enemyAdder = Observable.Interval(TimeSpan.FromSeconds(2.5)).ObserveOn(Dispatcher.CurrentDispatcher)
                .Subscribe(
                    _ =>
                    {
                        var ship = new Ship();
                        ship.AlignTo(new RectangleAdapter(this.GetBounds()), Alignment.ToLeftSide);
                        ship.Top -= 100;
                        Add(ship);
                    });

            destroyed.Subscribe(de =>
            {
                if (de.Winner is Actors.Tanky)
                {
                    Score += scoreTable[de.Defeated.GetType()];
                }
            });

            background = content.Load<Texture2D>("Background");
            Tanky = new Actors.Tanky();
            Add(Tanky);
        }

        public int Score { get; set; }

        public Tanky Tanky { get; }

        public override void Dispose()
        {
            enemyAdder.Dispose();
            base.Dispose();
        }

        protected override void ObjectAdded(IStageObject stageObject)
        {
            if (stageObject is IDestructable s)
            {
                destroyables[s] = s.Destroyed.Subscribe(destroyed);
            }
        }

        protected override void ObjectRemoved(IStageObject stageObject)
        {
            if (stageObject is Ship s)
            {
                if (destroyables.TryGetValue(s, out var d))
                {
                    d.Dispose();
                }

                destroyables.Remove(s);
            }
        }

        protected override void BeforeDraw(SpriteBatch spriteBatch)
        {
            spriteBatch.Draw(background, this.GetBounds(), Color.White);
        }

        public void SwitchWeapon()
        {
        }
    }
}