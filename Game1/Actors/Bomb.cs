using System;
using System.Reactive.Linq;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Content;
using Microsoft.Xna.Framework.Graphics;

namespace TankyReloaded.Actors
{
    internal class Bomb : StageObject
    {
        private static Texture2D texture;
        private double speed = 300;
        private readonly IDisposable exploder;

        public Bomb()
        {
            Width = 32;
            Height = 32;
            exploder = Observable.Timer(TimeSpan.FromSeconds(20)).Subscribe(_ => Dispose());
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
            HorizontalSpeed /= 2;
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
        }

        public double HorizontalSpeed { get; set; }

        private double Coerce(double v)
        {
            return double.IsInfinity(v) ? 0 : v;
        }
    }
}