using System;
using System.Reactive;
using System.Reactive.Linq;
using System.Reactive.Subjects;
using System.Windows.Threading;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Content;
using Microsoft.Xna.Framework.Graphics;
using SuperJMN.MonoGame;
using SuperJMN.MonoGame.Common;
using TankyApp.Actors.Shots;

namespace TankyApp.Actors
{
    internal class Bomb : StageObject, IDestructable
    {
        private static Texture2D texture;
        private readonly IDisposable exploder;
        private readonly ISubject<Unit> chainTrigger = new Subject<Unit>();
        private readonly ISubject<DefeatedEvent> destroyed = new Subject<DefeatedEvent>();

        public Bomb()
        {
            VerticalSpeed = 100;

            var explosion = chainTrigger.Delay(TimeSpan.FromMilliseconds(100)).Merge(Observable.Timer(TimeSpan.FromSeconds(3)).Select(_ => Unit.Default));
            exploder = explosion.ObserveOn(Dispatcher.CurrentDispatcher).Subscribe(_ => DestroyedBy(this));
        }

        private void DestroyedBy(IStageObject killer)
        {
            if (IsDestroyed)
            {
                return;
            }

            IsDestroyed = true;

            var explosion = this.IsTouchingGround() ? (IStageObject) new Explosion() : new AerialExplosion();
            explosion.AlignTo(this, Alignment.JoinBottoms);
            
            destroyed.OnNext(new DefeatedEvent(killer, this));
            Dispose();
            Stage.Add(explosion);
        }

        private void Dispose()
        {
            
            Stage.Remove(this);
            exploder.Dispose();
        }

        public bool IsDestroyed { get; set; }

        public override void Draw(SpriteBatch spriteBatch)
        {
            var sourceRectangle = new Rectangle(0, 0, texture.Width, texture.Height);
            spriteBatch.Draw(texture, Bounds, sourceRectangle, Color.White);
        }

        public override void LoadContent(ContentManager content)
        {
            texture = content.Load<Texture2D>("Bomb");
            this.SetWidth(32, new RectangleAdapter(texture.Bounds));
        }

        public override void Initialized()
        {
        }

        public override void Update(GameTime gameTime)
        {
            if (this.WillTouchGround(gameTime))
            {
                Top = Constants.GroundTop - Height;
                
            }
            else
            {
                Top += VerticalSpeed.Apply(gameTime);
            }

            if (this.IsTouchingGround())
            {
                HorizontalSpeed /= 2;
            }
            else
            {
                VerticalSpeed += Constants.Gravity;
            }

            if (Math.Abs(HorizontalSpeed) < 5)
            {
                HorizontalSpeed = 0;
            }

            Left += HorizontalSpeed.Apply(gameTime);
        }

        public override void CollideWith(IStageObject other)
        {
            if (other is Bomb)
            {
                var x1 = other.Left + other.Width / 2;
                var x2 = this.Left + this.Width / 2;

                var y1 = other.Left + other.Width / 2;
                var y2 = this.Left + this.Width / 2;

                var xr = x2 - x1;
                var yr = y2 - y1;
                
                HorizontalSpeed += Coerce(200 / xr);
                VerticalSpeed += Coerce(200 / yr);
            }

            if (other is Explosion)
            {
                chainTrigger.OnNext(Unit.Default);
                //var x1 = other.Left + other.Width / 2;
                //var x2 = this.Left + this.Width / 2;

                //var y1 = other.Left + other.Width / 2;
                //var y2 = this.Left + this.Width / 2;

                //var xr = x2 - x1;
                //var yr = y2 - y1;
                
                //HorizontalSpeed += Coerce(500 / xr * 2);
                //speed += Coerce(500 / yr  * 2);
            }

            if (other is Shot s)
            {
                DestroyedBy(s.Shooter);
            }
        }

        private static double Coerce(double v)
        {
            return double.IsInfinity(v) ? 0 : v;
        }

        public IObservable<DefeatedEvent> Destroyed => destroyed;
    }
}