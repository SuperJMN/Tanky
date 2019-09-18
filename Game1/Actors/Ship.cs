using System;
using System.Reactive.Linq;
using System.Windows.Threading;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Content;
using Microsoft.Xna.Framework.Graphics;
using SuperJMN.MonoGame;

namespace TankyReloaded.Actors
{
    internal class Ship : StageObject, IDisposable
    {
        private static Texture2D texture;
        private readonly IDisposable bombDropper;
        
        public Ship()
        {
            Height = 64;
            VerticalSpeed = Utils.Random.NextDouble() * 50;
            HorizontalSpeed = 200;

            bombDropper = ObservableMixin.PushRandomly(() => TimeSpan.FromMilliseconds(Utils.Random.Next(100, 2000)))
                .ObserveOn(Dispatcher.CurrentDispatcher)
                .Subscribe(_ =>
                {
                    if (Top + Height + 20 < Constants.GroundTop)
                    {
                        Stage.AddRelative(new Bomb(), this, RelativePosition.Bottom);
                    }
                });
        }

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
            Left -= gameTime.ElapsedGameTime.TotalSeconds * HorizontalSpeed;
            Top += gameTime.ElapsedGameTime.TotalSeconds * VerticalSpeed;

            if (this.IsOutOfBounds())
            {
                Dispose();
            }
        }

        public override void CollideWith(IStageObject other)
        {
            if (other is Shot)
            {
                Stage.AddRelative(new AerialExplosion(), this, RelativePosition.Center);
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