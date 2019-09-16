using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Content;
using Microsoft.Xna.Framework.Graphics;

namespace TankyReloaded.Actors
{
    internal class Ship : StageObject
    {
        private static Texture2D texture;
        private readonly double speed = 100;

        public Ship()
        {
            Height = 64;
        }

        public override void Draw(SpriteBatch spriteBatch)
        {
            var sourceRectangle = new Rectangle(0, 0, texture.Width, texture.Height);
            spriteBatch.Draw(texture, Bounds, sourceRectangle, Color.White);
        }

        public override void LoadContent(ContentManager content)
        {
            texture = content.Load<Texture2D>("Ship");
            Width = (double)texture.Width / texture.Height * Height;
        }

        public override void Update(GameTime gameTime)
        {
            Left -= gameTime.ElapsedGameTime.TotalSeconds * speed;
        }
    }
}