using System;
using System.Reactive;
using System.Reactive.Concurrency;
using System.Reactive.Linq;
using System.Threading;
using System.Threading.Tasks;
using System.Windows.Threading;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Content;
using Microsoft.Xna.Framework.Graphics;
using TimeSpan = System.TimeSpan;

namespace TankyReloaded.Actors
{
    internal class Ship : StageObject
    {
        private static Texture2D texture;
        private readonly double speed = 200;
        private readonly IDisposable bombDropper;

        public double VerticalSpeed { get; set; }

        private static int Number;

        public Ship()
        {
            Id = ++Number;
            Height = 64;
            VerticalSpeed = Utils.Random.NextDouble() * 50;

            bombDropper = ObservableMixin.PushRandomly(() => TimeSpan.FromMilliseconds(Utils.Random.Next(1000, 4000)))
                .ObserveOn(Dispatcher.CurrentDispatcher)
                .Subscribe(_ =>
                {
                    if (Top + Height +20 < Constants.GroundTop)
                    {
                        Stage.AddRelative(new Bomb(), this, RelativePosition.Bottom);
                    }
                });
        }

        public int Id { get; }

        public override void Draw(SpriteBatch spriteBatch)
        {
            var sourceRectangle = new Rectangle(0, 0, texture.Width, texture.Height);
            spriteBatch.Draw(texture, Bounds, sourceRectangle, Color.White);
        }

        public override void LoadContent(ContentManager content)
        {
            texture = content.Load<Texture2D>("Ship2");
            Width = (double)texture.Width / texture.Height * Height;
        }

        public override void Update(GameTime gameTime)
        {
            Left -= gameTime.ElapsedGameTime.TotalSeconds * speed;
            Top += gameTime.ElapsedGameTime.TotalSeconds * VerticalSpeed;
            if (Left + Width < 0)
            {
                Stage.Remove(this);
                bombDropper.Dispose();
            }
        }

        public override void CollideWith(IStageObject other)
        {
            if (other is Shot)
            {
                Stage.Remove(this);
                bombDropper.Dispose();
            }
        }
    }
}