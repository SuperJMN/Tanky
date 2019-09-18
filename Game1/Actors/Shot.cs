using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Content;
using Microsoft.Xna.Framework.Graphics;
using SuperJMN.MonoGame;

namespace TankyReloaded.Actors
{
    internal class Shot : StageObject
    {
        private static Texture2D texture;

        public Shot()
        {
            Width = 10;
            Height = 10;
            VerticalSpeed = 300;
        }

        public override void Draw(SpriteBatch spriteBatch)
        {
            var sourceRectangle = new Rectangle(0, 0, texture.Width, texture.Height);
            spriteBatch.Draw(texture, Bounds, sourceRectangle, Color.White);
        }

        public override void LoadContent(ContentManager content)
        {
            texture = content.Load<Texture2D>("Shot");
        }

        public override void Update(GameTime gameTime)
        {
            Left += VerticalSpeed.Apply(gameTime);
            if (this.IsOutOfBounds())
            {
                Dispose();
            }
        }

        public override void CollideWith(IStageObject other)
        {
            if (other is Ship || other is Bomb)
            {
                Stage.Remove(this);
            }
        }

        private void Dispose()
        {
            Stage.Remove(this);
        }
    }
}