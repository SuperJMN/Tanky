using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Content;
using Microsoft.Xna.Framework.Graphics;

namespace TankyReloaded.Actors
{
    internal class Shot : StageObject
    {
        private static Texture2D texture;
        private readonly double speed = 300;

        public Shot()
        {
            Width = 10;
            Height = 10;
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
            Left += gameTime.ElapsedGameTime.TotalSeconds * speed;
        }

        public override void CollideWith(IStageObject other)
        {
            if (other is Ship)
            {
                Stage.Remove(this);
            }
        }
    }
}