using System;
using System.Reactive.Linq;
using System.Windows.Threading;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Content;
using Microsoft.Xna.Framework.Graphics;
using SuperJMN.MonoGame;
using SuperJMN.MonoGame.Common;

namespace TankyReloaded.Actors
{
    internal class Ship : StageObject, IDisposable
    {
        private static Texture2D texture;
        private IDisposable bombDropper;
        private Texture2D rect;

        public Ship()
        {
            VerticalSpeed = Utils.Random.NextDouble() * 50;
            HorizontalSpeed = 200;
        }

        public override void Draw(SpriteBatch spriteBatch)
        {
            var sourceRectangle = new Rectangle(0, 0, texture.Width, texture.Height);
            //spriteBatch.Draw(rect, Bounds, sourceRectangle, Color.AliceBlue);
            spriteBatch.Draw(texture, Bounds, sourceRectangle, Color.White);
        }

        public override void LoadContent(ContentManager content)
        {
            texture = content.Load<Texture2D>("Ship2");
            rect = content.Load<Texture2D>("rect");
            this.SetHeight(64, new RectangleAdapter(texture.Bounds));

            bombDropper = ObservableMixin.PushRandomly(() => TimeSpan.FromMilliseconds(Utils.Random.Next(100, 2000)))
                .ObserveOn(Dispatcher.CurrentDispatcher)
                .Subscribe(_ =>
                {
                    if (Top + Height + 20 < Constants.GroundTop)
                    {
                        var stageObject = new Bomb();
                        stageObject.AlignTo(this, Alignment.ToBottomSide);
                        Stage.Add(stageObject);
                    }
                });
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
                var aerialExplosion = new AerialExplosion();
                aerialExplosion.AlignTo(this, Alignment.Center);
                Stage.Add(aerialExplosion);
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