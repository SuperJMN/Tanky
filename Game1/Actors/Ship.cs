using System;
using System.Reactive.Linq;
using System.Windows.Threading;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Content;
using Microsoft.Xna.Framework.Graphics;

namespace TankyReloaded.Actors
{
    internal class Ship : StageObject, IDisposable
    {
        private static Texture2D texture;
        private readonly IDisposable bombDropper;
        private readonly double speed = 200;

        public Ship()
        {
            Height = 64;
            VerticalSpeed = Utils.Random.NextDouble() * 50;

            bombDropper = ObservableMixin.PushRandomly(() => TimeSpan.FromMilliseconds(Utils.Random.Next(1000, 4000)))
                .ObserveOn(Dispatcher.CurrentDispatcher)
                .Subscribe(_ =>
                {
                    if (Top + Height + 20 < Constants.GroundTop)
                    {
                        Stage.AddRelative(new Bomb(), this, RelativePosition.Bottom);
                    }
                });
        }

        public double VerticalSpeed { get; set; }

        public override void Draw(SpriteBatch spriteBatch)
        {
            var sourceRectangle = new Rectangle(0, 0, texture.Width, texture.Height);
            spriteBatch.Draw(texture, Bounds, sourceRectangle, Color.White);
        }

        public override void LoadContent(ContentManager content)
        {
            texture = content.Load<Texture2D>("Ship2");
            Width = (double) texture.Width / texture.Height * Height;
        }

        public override void Update(GameTime gameTime)
        {
            Left -= gameTime.ElapsedGameTime.TotalSeconds * speed;
            Top += gameTime.ElapsedGameTime.TotalSeconds * VerticalSpeed;
            if (Left + Width < 0)
            {
                Dispose();
            }
        }

        public override void CollideWith(IStageObject other)
        {
            if (other is Shot)
            {
                Dispose();
            }
        }

        public void Dispose()
        {
            Stage.Remove(this);
            bombDropper.Dispose();
        }
    }
}