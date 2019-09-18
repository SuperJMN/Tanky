using System;
using System.Reactive;
using System.Reactive.Linq;
using System.Reactive.Subjects;
using System.Timers;
using System.Windows.Threading;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Content;
using Microsoft.Xna.Framework.Graphics;

namespace TankyReloaded.Actors
{
    internal class Bomb : StageObject
    {
        private static Texture2D texture;
        private double speed = 100;
        private readonly IDisposable exploder;
        private readonly ISubject<Unit> chainTrigger = new Subject<Unit>();

        public Bomb()
        {
            Width = 32;
            Height = 40;

            var explosion = chainTrigger.Delay(TimeSpan.FromMilliseconds(100)).Merge(Observable.Timer(TimeSpan.FromSeconds(3)).Select(_ => Unit.Default));
            exploder = explosion.ObserveOn(Dispatcher.CurrentDispatcher).Subscribe(_ => Explode());
        }

        private void Explode()
        {
            Stage.AddRelative(new Explosion(), this, RelativePosition.Center);
            Dispose();
        }

        private void Dispose()
        {
            Stage.Remove(this);
            exploder.Dispose();
        }

        public override void Draw(SpriteBatch spriteBatch)
        {
            var sourceRectangle = new Rectangle(0, 0, texture.Width, texture.Height);
            spriteBatch.Draw(texture, Bounds, sourceRectangle, Color.White);
        }

        public override void LoadContent(ContentManager content)
        {
            texture = content.Load<Texture2D>("Bomb");
        }

        public override void Update(GameTime gameTime)
        {
            if (Top + Height < Constants.GroundTop)
            {
                Top += gameTime.ElapsedGameTime.TotalSeconds * speed;
            }
            else
            {
                Top = Constants.GroundTop - Height;
            }

            Left += HorizontalSpeed * gameTime.ElapsedGameTime.TotalSeconds;
            
            if (Top + Height  >= Constants.GroundTop)
            {
                HorizontalSpeed /= 2;
            }
            else
            {
                speed += Constants.Gravity;
            }

            if (Math.Abs(HorizontalSpeed) < 5)
            {
                HorizontalSpeed = 0;
            }
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
                speed += Coerce(200 / yr);
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
        }

        public double HorizontalSpeed { get; set; }

        private double Coerce(double v)
        {
            return double.IsInfinity(v) ? 0 : v;
        }
    }
}